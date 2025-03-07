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
        self.channel.invokeMethod("onInteraction", arguments: ["interaction": mapFromTransactInteraction(interaction)])
    }
    
    func onDataRequest(_ request: TransactDataRequest) {
        self.channel.invokeMethod("onDataRequest", arguments: ["request": mapFromTransactDataRequest(request)])
    }

    func onLaunch() {
        self.channel.invokeMethod("onLaunch", arguments: nil)
    }
    
    func onCompletion(_ response: TransactResponse) {
        var arguments : Any?;
        
        switch response {
            case .finished(let value):
                arguments = ["type": "finished", "response": mapFromTransactResponseData(value)];
            
            case .closed(let value):
                arguments = ["type": "closed", "response": mapFromTransactResponseData(value)];
            
            case .error(let error):
                var code: String;
                
                switch error {
                    case .invalidConfig:
                        code = "invalidConfig"
                    case .unableToConnectToTransact:
                        code = "unableToConnectToTransact"
                    default:
                        code = "unknownError";
                        break;
                }
            
                arguments = ["type": "error", "error": code];

            default:
                break;
        }
        
        if(arguments != nil) {
            self.channel.invokeMethod("onCompletion", arguments: arguments)
        }
    }

    func onAuthStatusUpdate(_ authStatus: TransactAuthStatusUpdate) {
        self.channel.invokeMethod("onAuthStatusUpdate", arguments: ["auth": mapFromTransactAuthStatusUpdate(authStatus)])
    }
    
    func onTaskStatusUpdate(_ taskStatus: TransactTaskStatusUpdate) {
        self.channel.invokeMethod("onTaskStatusUpdate", arguments: ["task": mapFromTransactTaskStatusUpdate(taskStatus)])
    }
    // MARK: - Helpers

    func mapFromTransactAuthStatusUpdate(_ value: TransactAuthStatusUpdate) -> [String: Any?] {
        return [
            "status": value.status.rawValue,
            "company": mapFromTransactCompany(value.company),
        ]
    }

    func mapFromTransactTaskStatusUpdate(_ value: TransactTaskStatusUpdate) -> [String: Any?] {
        var switchData: [String: Any?]? = nil
        if let data = value.switchData {
            var paymentMethod: [String: Any?] = [
                "_id": data.paymentMethod.id,
                "title": data.paymentMethod.title,
                "type": data.paymentMethod.type.rawValue
            ]

            if data.paymentMethod.type == .card {
                paymentMethod["expiry"] = data.paymentMethod.expiry
                paymentMethod["brand"] = data.paymentMethod.brand
                paymentMethod["lastFour"] = data.paymentMethod.lastFour
            } else if data.paymentMethod.type == .bank {
                paymentMethod["routingNumber"] = data.paymentMethod.routingNumber
                paymentMethod["accountType"] = data.paymentMethod.accountType
                paymentMethod["lastFourAccountNumber"] = data.paymentMethod.lastFourAccountNumber
            }

            switchData = ["paymentMethod": paymentMethod]
        }

        var managedBy: [String: Any?]? = nil
        if let data = value.managedBy {
            managedBy = ["company": mapFromTransactCompany(data.company)]
        }

        return [
            "status": value.status.rawValue,
            "taskId": value.taskId,
            "product": value.product.rawValue,
            "company": mapFromTransactCompany(value.company),
            "failReason": value.failReason,
            "switchData": switchData,
            "depositData": value.depositData != nil ? [
                "accountType": value.depositData?.accountType,
                "distributionAmount": value.depositData?.distributionAmount,
                "distributionType": value.depositData?.distributionType,
                "lastFour": value.depositData?.lastFour,
                "routingNumber": value.depositData?.routingNumber,
                "title": value.depositData?.title
            ] : nil,
            "managedBy": managedBy
        ]
    }

    func mapFromTransactInteraction(_ value: TransactInteraction) -> [String: Any?] {
        return [
            "name" : value.name,
            "description" : value.description,
            "value" : value.value,
            "language" : value.language,
            "company" : value.company,
            "customer" : value.customer,
            "payroll" : value.payroll,
            "product" : value.product?.rawValue,
            "additionalProduct" : value.additionalProduct?.rawValue,
        ]
    }
    
    func mapFromTransactDataRequest(_ value: TransactDataRequest) -> [String: Any?] {
        return [
            "fields": value.fields,
            "data": value.data,
            "identifier": value.identifier,
        ];
    }
    
    func mapFromTransactResponseData(_ value: TransactResponse.ResponseData) -> [String: Any?] {
        return [
            "taskId": value.taskId,
            "data": value.data,
            "handoff": value.handoff,
            "reason": value.reason,
        ];
    }

    func mapFromTransactCompany(_ company: TransactCompany?) -> [String: Any?] {
        return [
            "_id": company?.id,
            "name": company?.name,
            "branding": company?.branding != nil ? [
                "color": company?.branding?.color,
                "logo": [
                    "url": company?.branding?.logo.url,
                    "backgroundColor": company?.branding?.logo.backgroundColor
                ]
            ] : nil
        ]
    }
}
