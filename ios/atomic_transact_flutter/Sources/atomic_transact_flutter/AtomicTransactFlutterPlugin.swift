import Flutter
import UIKit
import AtomicTransact

public class AtomicTransactFlutterPlugin: NSObject, FlutterPlugin {

    let channel: FlutterMethodChannel;
    var pausedTransactRef: Atomic.PausedTransactRef?
    /// Launches that haven't cleaned up yet, keyed by the instance id Dart generated for each.
    private var instances: [String: TransactInstance] = [:]
    /// The dismiss or hide still in progress. Presenting waits for it, or the new Transact would be
    /// presented on top of one that is about to go, and go with it.
    private var pendingDismissal: Task<Void, Never>?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "atomic_transact_flutter", binaryMessenger: registrar.messenger())
        let instance = AtomicTransactFlutterPlugin(withChannel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    init(withChannel channel: FlutterMethodChannel) {
        self.channel = channel;
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch(call.method) {
          
        case "presentTransact":
            let arguments = call.arguments as! [String: Any]
            let transactPath = arguments["transactPath"] as! String
            let apiPath = arguments["apiPath"] as! String
            let pluginVersion = arguments["pluginVersion"] as? String ?? ""
            let debugEnabled = arguments["debug"] as? Bool ?? false
            let decoder = JSONDecoder()

            let presentationStyle = getPresentationStyle(from: arguments["presentationStyleIOS"] as? String)

            // Dart keeps this launch's handlers until it hears back, so every path must call result.
            guard let instanceId = arguments["instanceId"] as? String,
                  let configuration = arguments["configuration"] as? [String: Any] else {
                result(FlutterError(code: "ConfigError", message: "Missing instanceId or configuration", details: nil))
                return
            }

            do {
                var json = configuration
                let suffix = pluginVersion.isEmpty ? "flutter" : "flutter-\(pluginVersion)"
                json["platform"] = AtomicConfig.Platform(suffixed: suffix).encode()

                // JSONSerialization raises an exception Swift can't catch for values like NaN.
                guard JSONSerialization.isValidJSONObject(json) else {
                    result(FlutterError(code: "ConfigError", message: "Configuration can't be encoded as JSON", details: nil))
                    return
                }
                let data = try JSONSerialization.data(withJSONObject: json, options: [])

                var config = try decoder.decode(AtomicConfig.self, from: data)

                Task { @MainActor in
                    await Atomic.setDebug(isEnabled: debugEnabled, forwardLogs: { logMessage in
                        DispatchQueue.main.async {
                            self.channel.invokeMethod("onDebugLog", arguments: ["message": logMessage])
                        }
                    })

                    await self.pendingDismissal?.value
                    guard let controller = await presentationSource() else {
                        result(FlutterError(code: "PlatformError", message: "No keyWindow found", details: nil))
                        return
                    }

                    let instance = TransactInstance(instanceId: instanceId, channel: self.channel)
                    instance.onEnded = { [weak self] in self?.instances[instanceId] = nil }
                    self.instances[instanceId] = instance

                    Atomic.presentTransact(from: controller, config: config, environment: .custom(transactPath: transactPath, apiPath: apiPath), presentationStyle: presentationStyle, onInteraction: instance.onInteraction, onDataRequest: instance.onDataRequest, onAuthStatusUpdate: instance.onAuthStatusUpdate, onTaskStatusUpdate: instance.onTaskStatusUpdate, onLaunch: instance.onLaunch, onCompletion: instance.onCompletion, onCleanup: instance.onCleanup)

                    // UIKit drops a presentation it can't make without calling back, and Transact
                    // then never sends an event. (Action tasks run off screen and aren't presented.)
                    let presented = controller.presentedViewController
                    guard presented != nil || config.tasks?.first?.operation == .action else {
                        self.instances[instanceId] = nil
                        result(FlutterError(code: "PresentError", message: "Transact could not be presented", details: nil))
                        return
                    }
                    instance.viewController = presented
                    result(nil)
                }
            } catch let error {
                result(FlutterError(code: "ConfigError", message: String(describing: error), details: nil))
            }
        case "dismissTransact":
            // The paused Transact, if any, is dismissed too and its launch ends, so it can't be resumed.
            pausedTransactRef = nil
            pendingDismissal = Task { @MainActor in
                let shown = self.instances.values.filter { instance in
                    guard let controller = instance.viewController else { return false }
                    return isPresented(controller) && !controller.isBeingDismissed
                }

                Atomic.dismissTransact()
                await waitForSDK()

                // The SDK's dismissal does nothing to a Transact that is still animating in, and
                // only dismisses whatever another Transact presented on top of it. Dismissing the
                // lowest one left also dismisses everything above it.
                let lowest = presentationChain().first { controller in
                    shown.contains { $0.viewController === controller }
                }
                lowest?.presentingViewController?.dismiss(animated: true)
                await waitForTransitions()

                // A Transact dismissed along with the one under it isn't told, so end its launch here.
                shown.forEach { $0.onCleanup() }
                result(nil)
            }
            return
        case "hideTransact":
            pendingDismissal = Task { @MainActor in
                Atomic.hideTransact()
                // So a launch right after presents from the right view controller.
                await waitForSDK()
                result(nil)
            }
            return
        case "pauseTransact":
            Task { @MainActor in
                do {
                    let ref = try await Atomic.pauseTransact()
                    self.pausedTransactRef = ref
                    result(nil)
                } catch {
                    result(FlutterError(code: "PauseTransactError", message: "No Transact is currently presented", details: nil))
                }
            }
            return
        case "resumeTransact":
            Task { @MainActor in
                await self.pendingDismissal?.value
                if let ref = self.pausedTransactRef,
                   let controller = await presentationSource() {
                    ref.resume(source: controller)
                    self.pausedTransactRef = nil
                    result(nil)
                } else {
                    result(FlutterError(code: "ResumeTransactError", message: "No paused Transact to resume", details: nil))
                }
            }
            return

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - Transact Delegate

/// The callbacks for one presented Transact. Every event is tagged with the `instanceId` Dart
/// generated for the launch, so Dart can route it to that launch's handlers.
private final class TransactInstance {
    let instanceId: String
    let channel: FlutterMethodChannel
    /// The Transact view controller presented for this launch.
    weak var viewController: UIViewController?
    /// Called once, when the launch ends.
    var onEnded: (() -> Void)?
    private var didCleanup = false

    init(instanceId: String, channel: FlutterMethodChannel) {
        self.instanceId = instanceId
        self.channel = channel
    }

    private func emit(_ method: String, _ data: Any?) {
        guard !didCleanup else { return }
        let arguments: [String: Any?] = ["instanceId": instanceId, "data": data]
        channel.invokeMethod(method, arguments: arguments)
    }

    func onInteraction(_ interaction: TransactInteraction) {
        emit("onInteraction", interaction.toFlutterMap())
    }

    /// Forwards the request to Dart and waits for the handler's reply, which the SDK then
    /// dispatches back into Transact. A nil return (no handler, an error, or an empty reply)
    /// sends nothing, leaving Transact waiting as it would with no handler at all.
    func onDataRequest(_ request: TransactDataRequest) async -> TransactDataResponse? {
        await withCheckedContinuation { (continuation: CheckedContinuation<TransactDataResponse?, Never>) in
            DispatchQueue.main.async {
                guard !self.didCleanup else {
                    continuation.resume(returning: nil)
                    return
                }
                let arguments: [String: Any?] = ["instanceId": self.instanceId, "data": request.toFlutterMap()]
                self.channel.invokeMethod("onDataRequest", arguments: arguments) { reply in
                    continuation.resume(returning: Self.dataResponse(from: reply))
                }
            }
        }
    }

    /// Decodes the Dart reply into a `TransactDataResponse`. `reply` is a `FlutterError` when the
    /// Dart handler threw, and `FlutterMethodNotImplemented` when no handler is registered; both
    /// fail the cast and decode to nil.
    private static func dataResponse(from reply: Any?) -> TransactDataResponse? {
        guard let json = reply as? [String: Any], !json.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: json, options: []),
              let response = try? JSONDecoder().decode(TransactDataResponse.self, from: data)
        else {
            return nil
        }

        return response
    }

    func onLaunch() {
        emit("onLaunch", nil)
    }

    func onCompletion(_ response: TransactResponse) {
        switch response {
            case .finished(let value):
                emit("onCompletion", ["type": "finished", "response": value.toFlutterMap()])

            case .closed(let value):
                emit("onCompletion", ["type": "closed", "response": value.toFlutterMap()])

            case .error(let error):
                let code: String = switch error {
                    case .invalidConfig: "invalidConfig"
                    case .unableToConnectToTransact: "unableToConnectToTransact"
                    default: "unknownError"
                }
                emit("onCompletion", ["type": "error", "error": code])
                // Transact failed to launch, so nothing else will arrive. The SDK only cleans up
                // once its dismissal finishes, so end the task now instead of relying on that.
                onCleanup()

            case .transactDismissed:
                // Atomic.dismissTransact() never cleans up, so end the task here.
                onCleanup()

            default:
                break
        }
    }

    func onAuthStatusUpdate(_ authStatus: TransactAuthStatusUpdate) {
        emit("onAuthStatusUpdate", authStatus.toFlutterMap())
    }

    func onTaskStatusUpdate(_ taskStatus: TransactTaskStatusUpdate) {
        emit("onTaskStatusUpdate", taskStatus.toFlutterMap())
    }

    /// Ends the task, at most once. It's called by the SDK and by the paths where the SDK won't
    /// clean up.
    func onCleanup() {
        guard !didCleanup else { return }
        emit("onCleanup", nil)
        didCleanup = true
        onEnded?()
        onEnded = nil
    }
}

// MARK: - Transact Type Extensions

extension TransactCompany {
    func toFlutterMap() -> [String: Any?] {
        return [
            "_id": id,
            "name": name,
            "branding": branding != nil ? [
                "color": branding?.color,
                "logo": [
                    "url": branding?.logo.url,
                    "backgroundColor": branding?.logo.backgroundColor
                ]
            ] : nil
        ]
    }
}

extension TransactAuthStatusUpdate {
    func toFlutterMap() -> [String: Any?] {
        return [
            "status": status.rawValue,
            "company": company.toFlutterMap(),
        ]
    }
}

extension TransactInteraction {
    func toFlutterMap() -> [String: Any?] {
        return [
            "name": name,
            "description": description,
            "value": value,
            "language": language,
            "company": company,
            "customer": customer,
            "payroll": payroll,
            "product": product?.rawValue,
            "additionalProduct": additionalProduct?.rawValue,
        ]
    }
}

extension TransactDataRequest {
    func toFlutterMap() -> [String: Any?] {
        return [
            "taskId": taskId,
            "userId": userId,
            "identifier": identifier,
            "fields": fields,
            "data": data,
        ]
    }
}

extension TransactResponse.ResponseData {
    func toFlutterMap() -> [String: Any?] {
        return [
            "taskId": taskId,
            "data": data,
            "handoff": handoff,
            "reason": reason,
        ]
    }
}

extension TransactTaskStatusUpdate {
    func toFlutterMap() -> [String: Any?] {
        var result: [String: Any?] = [
            "taskId": taskId,
            "product": product.rawValue,
            "status": status.rawValue,
            "failReason": failReason,
            "company": company.toFlutterMap()
        ]
        
        if let switchData = switchData {
            var switchMap: [String: Any] = [:]
            
            let payment = switchData.paymentMethod
            var paymentMap: [String: Any] = [
                "id": payment.id,
                "title": payment.title,
                "type": payment.type.rawValue
            ]
            
            switch payment.type {
            case .card:
                paymentMap["expiry"] = payment.expiry
                paymentMap["brand"] = payment.brand
                paymentMap["lastFour"] = payment.lastFour
            case .bank:
                paymentMap["routingNumber"] = payment.routingNumber
                paymentMap["accountType"] = payment.accountType
                paymentMap["lastFourAccountNumber"] = payment.lastFourAccountNumber
            }
            
            switchMap["paymentMethod"] = paymentMap
            result["switchData"] = switchMap
        }
        
        if let depositData = depositData {
            result["depositData"] = [
                "accountType": depositData.accountType,
                "lastFour": depositData.lastFour,
                "routingNumber": depositData.routingNumber,
                "title": depositData.title,
                "distributionAmount": depositData.distributionAmount,
                "distributionType": depositData.distributionType?.description
            ]
        }
        
        if let managedBy = managedBy {
            result["managedBy"] = ["company": managedBy.company.toFlutterMap()]
        }
        
        return result
    }
}

// MARK: - Helper Functions

/// The key window's root view controller followed by each view controller presented on top of it.
@MainActor
private func presentationChain() -> [UIViewController] {
    var chain: [UIViewController] = []
    var controller = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController
    while let current = controller {
        chain.append(current)
        controller = current.presentedViewController
    }
    return chain
}

@MainActor
private func isPresented(_ controller: UIViewController) -> Bool {
    presentationChain().contains { $0 === controller }
}

/// Waits, for up to two seconds, until nothing in the key window is animating a presentation or a
/// dismissal. UIKit drops a presentation that starts during one without calling back.
@MainActor
private func waitForTransitions() async {
    var attempts = 0
    while attempts < 40, presentationChain().contains(where: { $0.transitionCoordinator != nil }) {
        attempts += 1
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
}

/// Waits for the SDK to act on a dismiss or hide. It does so after a short delay, then animates.
@MainActor
private func waitForSDK() async {
    try? await Task.sleep(nanoseconds: 100_000_000)
    await waitForTransitions()
}

/// The view controller to present Transact from: the top of the key window's presentation chain,
/// once nothing in it is animating. Presenting from a view controller that is already presenting
/// makes UIKit drop the presentation.
@MainActor
private func presentationSource() async -> UIViewController? {
    await waitForTransitions()
    return presentationChain().last
}

private func getPresentationStyle(from styleString: String?) -> UIModalPresentationStyle {
    guard let styleString = styleString else {
        return .formSheet
    }
    
    switch styleString {
    case "fullScreen":
        return .fullScreen
    case "formSheet":
        return .formSheet
    default:
        return .formSheet
    }
}
