import Flutter
import UIKit
import AtomicTransact

public class AtomicTransactFlutterPlugin: NSObject, FlutterPlugin {

    let channel: FlutterMethodChannel;
    var pausedTransactRef: Atomic.PausedTransactRef?
    
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

            if let configuration = arguments["configuration"] as? [String: Any] {
                do {
                    var json = configuration
                    let suffix = pluginVersion.isEmpty ? "flutter" : "flutter-\(pluginVersion)"
                    json["platform"] = AtomicConfig.Platform(suffixed: suffix).encode()

                    guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else { return }

                    var config = try decoder.decode(AtomicConfig.self, from: data)

                    Task { @MainActor in
                        await Atomic.setDebug(isEnabled: debugEnabled, forwardLogs: { logMessage in
                            DispatchQueue.main.async {
                                self.channel.invokeMethod("onDebugLog", arguments: ["message": logMessage])
                            }
                        })

                        if let controller = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController {
                            Atomic.presentTransact(from: controller, config: config, environment: .custom(transactPath: transactPath, apiPath: apiPath), presentationStyle: presentationStyle, onInteraction: onInteraction, onDataRequest: onDataRequest, onAuthStatusUpdate: onAuthStatusUpdate, onTaskStatusUpdate: onTaskStatusUpdate, onLaunch: onLaunch, onCompletion: onCompletion)
                            result(nil)
                        } else {
                            result(FlutterError(code: "PlatformError", message: "No keyWindow found", details: nil))
                        }
                    }
                } catch let error {
                    result(FlutterError(code: "ConfigError", message: String(describing: error), details: nil))
                }
            }
            break;
        case "dismissTransact":
            Atomic.dismissTransact()
        case "hideTransact":
            Atomic.hideTransact()
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
                if let ref = self.pausedTransactRef,
                   let controller = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController {
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
    
    // MARK: - Transact Delegate
    
    func onInteraction(_ interaction: TransactInteraction) {
        self.channel.invokeMethod("onInteraction", arguments: ["interaction": interaction.toFlutterMap()])
    }
    
    /// Forwards the request to Dart and waits for the handler's reply, which the SDK then
    /// dispatches back into Transact. A nil return (no handler, an error, or an empty reply)
    /// sends nothing, leaving Transact waiting as it would with no handler at all.
    func onDataRequest(_ request: TransactDataRequest) async -> TransactDataResponse? {
        await withCheckedContinuation { (continuation: CheckedContinuation<TransactDataResponse?, Never>) in
            DispatchQueue.main.async {
                self.channel.invokeMethod("onDataRequest", arguments: ["request": request.toFlutterMap()]) { reply in
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
        self.channel.invokeMethod("onLaunch", arguments: nil)
    }

    func onCompletion(_ response: TransactResponse) {
        var arguments: Any?
        
        switch response {
            case .finished(let value):
                arguments = ["type": "finished", "response": value.toFlutterMap()]
            
            case .closed(let value):
                arguments = ["type": "closed", "response": value.toFlutterMap()]
            
            case .error(let error):
                let code: String = switch error {
                    case .invalidConfig: "invalidConfig"
                    case .unableToConnectToTransact: "unableToConnectToTransact"
                    default: "unknownError"
                }
                arguments = ["type": "error", "error": code]
            
            default:
                break
        }
        
        if let arguments = arguments {
            self.channel.invokeMethod("onCompletion", arguments: arguments)
        }
    }

    func onAuthStatusUpdate(_ authStatus: TransactAuthStatusUpdate) {
        self.channel.invokeMethod("onAuthStatusUpdate", arguments: ["auth": authStatus.toFlutterMap()])
    }
    
    func onTaskStatusUpdate(_ taskStatus: TransactTaskStatusUpdate) {
        self.channel.invokeMethod("onTaskStatusUpdate", arguments: ["task": taskStatus.toFlutterMap()])
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
