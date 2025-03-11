import Flutter
import UIKit
import AtomicTransact

public class SwiftAtomicTransactFlutterPlugin: NSObject, FlutterPlugin {
    
    let channel: FlutterMethodChannel;
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "atomic_transact_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftAtomicTransactFlutterPlugin(withChannel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    init(withChannel channel: FlutterMethodChannel) {
        self.channel = channel;
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch(call.method) {
          
        case "presentTransact":
            let arguments = call.arguments as! [String: Any]
            let environmentURL = arguments["environmentURL"] as! String
            let decoder = JSONDecoder()
            
            if let configuration = arguments["configuration"] as? [String: Any] {
                do {
                    var json = configuration

                    if var platform = AtomicConfig.Platform().encode() as? [String: Any] {
                        platform["sdkVersion"] = platform["sdkVersion"] as! String + "-flutter"
                        json["platform"] = platform
                    }

                    guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else { return }

                    var config = try decoder.decode(AtomicConfig.self, from: data)
                    
                    if let controller = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController {
                        Atomic.presentTransact(from: controller, config: config, environment: .custom(path: environmentURL), onInteraction: onInteraction, onDataRequest: onDataRequest, onAuthStatusUpdate: onAuthStatusUpdate, onTaskStatusUpdate: onTaskStatusUpdate, onCompletion: onCompletion)
                        result(nil)
                    } else {
                        result(FlutterError(code: "PlatformError", message: "No keyWindow found", details: nil))
                    }
                } catch let error {
                    result(FlutterError(code: "ConfigError", message: String(describing: error), details: nil))
                }
            }
            break;
        case "presentAction":
            let arguments = call.arguments as! [String: Any]
            let id = arguments["id"] as! String
            let environmentURL = arguments["environmentURL"] as! String
            if let controller = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController {
                Atomic.presentAction(from: controller, id: id, environment: .custom(path: environmentURL), onLaunch: onLaunch, onAuthStatusUpdate: onAuthStatusUpdate, onTaskStatusUpdate: onTaskStatusUpdate, onCompletion: onCompletion)
                result(nil)
            } else {
                result(FlutterError(code: "PlatformError", message: "No keyWindow found", details: nil))
            }
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Transact Delegate
    
    func onInteraction(_ interaction: TransactInteraction) {
        self.channel.invokeMethod("onInteraction", arguments: ["interaction": interaction.toFlutterMap()])
    }
    
    func onDataRequest(_ request: TransactDataRequest) {
        self.channel.invokeMethod("onDataRequest", arguments: ["request": request.toFlutterMap()])
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
            "fields": fields,
            "data": data,
            "identifier": identifier,
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
