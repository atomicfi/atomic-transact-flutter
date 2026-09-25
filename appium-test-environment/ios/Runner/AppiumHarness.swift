import Flutter
import OSLog
import UIKit

/// The native side of the `atomictest/harness` channel. It only moves data between the suite and
/// Dart: launch parameters, log lines, alerts and commands. Transact itself is driven from Dart
/// through the plugin, which is what the suite is testing.
final class AppiumHarness: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
    private static let logger = Logger(
        subsystem: "com.atomicfi.AppiumTestEnvironment.flutter",
        category: "AppiumTestEnvironment"
    )

    private let channel: FlutterMethodChannel
    private let alerts = AlertPresenter()

    private init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "atomictest/harness", binaryMessenger: registrar.messenger())
        let instance = AppiumHarness(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        // URLs opened in the app reach plugins through the scene: the suite sends
        // `atomictest://pause` and `atomictest://resume`.
        registrar.addSceneDelegate(instance)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "getLaunchExtras":
            // The suite launches with `mobile: launchApp` and these as environment variables.
            result(ProcessInfo.processInfo.environment.filter { $0.key.hasPrefix("TRANSACT_") })
        case "log":
            Self.log(arguments["message"] as? String ?? "")
            result(nil)
        case "showAlert":
            alerts.enqueue(
                title: arguments["title"] as? String ?? "",
                message: arguments["message"] as? String,
                button: arguments["button"] as? String ?? "Okay"
            ) {
                result(nil)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        let commands = URLContexts.map(\.url).filter { $0.scheme == "atomictest" }
        for url in commands {
            Self.log("Received command URL \(url.absoluteString)")
            channel.invokeMethod("command", arguments: ["name": url.host ?? "", "extras": [String: String]()])
        }
        // Handled here, so Flutter does not also try to route the URL.
        return !commands.isEmpty
    }

    /// Default level and public: `log stream`, which the suite reads, leaves out info and debug
    /// entries and shows interpolated values as `<private>` unless they are marked public.
    static func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
    }
}

/// Presents the harness's alerts one at a time, on top of whatever is on screen, Transact included.
/// XCUITest only sees the topmost alert, and the specs find each one by its title and button.
/// Used on the main thread only: channel calls, UIKit callbacks and the retry timer all run there.
private final class AlertPresenter {
    private struct Pending {
        let title: String
        let message: String?
        let button: String
        let acknowledged: () -> Void
    }

    /// How long to wait for a presentation or dismissal in progress to finish: UIKit drops an alert
    /// presented over a view controller that is still moving.
    private static let retryInterval: TimeInterval = 0.1
    private static let maxAttempts = 100

    private var queue: [Pending] = []
    private var showing = false

    func enqueue(title: String, message: String?, button: String, acknowledged: @escaping () -> Void) {
        queue.append(Pending(title: title, message: message, button: button, acknowledged: acknowledged))
        presentNext()
    }

    private func presentNext(attempt: Int = 1) {
        guard !showing, let next = queue.first else { return }

        guard let top = topViewController(), !isTransitioning(top) else {
            if attempt < Self.maxAttempts {
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.retryInterval) {
                    self.presentNext(attempt: attempt + 1)
                }
            } else {
                AppiumHarness.log("Could not present alert \(next.title): the screen never settled")
                queue.removeFirst()
                next.acknowledged()
                presentNext()
            }
            return
        }

        queue.removeFirst()
        showing = true
        let alert = UIAlertController(title: next.title, message: next.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: next.button, style: .default) { _ in
            self.showing = false
            next.acknowledged()
            self.presentNext()
        })
        AppiumHarness.log("Presenting alert \(next.title) over \(type(of: top)) (attempt \(attempt))")
        top.present(alert, animated: false)
    }

    private func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }

    private func isTransitioning(_ controller: UIViewController) -> Bool {
        controller.isBeingPresented || controller.isBeingDismissed || controller.transitionCoordinator != nil
    }
}
