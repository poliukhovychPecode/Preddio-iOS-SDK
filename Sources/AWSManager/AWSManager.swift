import Foundation
import AWSIoT
import AWSCognitoIdentityProvider
import AWSCore

protocol AWSManagerDelegate: AnyObject {
    func attachPolicy(with siteID: String, cognitoId: String, withConnect: Bool)
}

final public class AWSManager {
    
    static public let shared = AWSManager()
    
    @Published var registered: Bool = false
    var clientId: String = ""
    
    private var iotDataManager: AWSIoTDataManager!
    private var iotManager: AWSIoTManager!
    private var iot: AWSIoT!
    private var credentialsProvider: AWSCognitoCredentialsProvider?
    private var needToReconnect = false
    private let updateTime = 15 * 60
    private var updateTimer: Timer?
    private static var configSetter: AWSConfig?
    private let config: AWSConfig
    
    internal var siteId: String?
    
    weak var delegate: AWSManagerDelegate?
    
    // MARK: call before .shared
    class func setup(_ config: AWSConfig){
        AWSManager.configSetter = config
    }
    
    private init() {
        guard let config = AWSManager.configSetter else {
            fatalError("Error - you must call setup before accessing")
        }
        self.config = config
    }
        
    internal func registerManager() {
        var serviceConfiguration = AWSServiceConfiguration(
            region: config.awsRegion,
            credentialsProvider: nil
        )
        
        let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(
            clientId: config.clientID,
            clientSecret: nil,
            poolId: config.poolID
        )
        
        AWSCognitoIdentityUserPool.register(
            with: serviceConfiguration,
            userPoolConfiguration: userPoolConfiguration,
            forKey: config.userPoolKey
        )
        
        let pool = AWSCognitoIdentityUserPool(forKey: config.userPoolKey)
        credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: config.awsRegion,
            identityPoolId: config.identityPoolID,
            identityProviderManager: pool
        )
        
        serviceConfiguration = AWSServiceConfiguration(
            region: config.awsRegion,
            credentialsProvider: credentialsProvider
        )
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfiguration
    }
    
    func getAWSClientID(siteId: String, withConnect: Bool = false) {
        getAWSClientID(credentials: credentialsProvider) { [weak self] clientId, error in
            guard let self = self,
                  let clientId = clientId, !clientId.isEmpty else {
                print(error?.localizedDescription as Any)
                return
            }
            self.delegate?.attachPolicy(with: siteId,
                                        cognitoId: clientId,
                                        withConnect: withConnect)
        }
    }
    
    private func initializeDataPlane(credentialsProvider: AWSCredentialsProvider?) {
        let iotEndPoint = AWSEndpoint(urlString: config.ioTEndpoint)
        let iotDataConfiguration = AWSServiceConfiguration(
            region: config.awsRegion,
            endpoint: iotEndPoint,
            credentialsProvider: credentialsProvider
        )
        let mqttConfig = AWSIoTMQTTConfiguration(
            keepAliveTimeInterval: 30.0,
            baseReconnectTimeInterval: 1.0,
            minimumConnectionTimeInterval: 20.0,
            maximumReconnectTimeInterval: 8.0,
            runLoop: RunLoop.current,
            runLoopMode: RunLoop.Mode.default.rawValue,
            autoResubscribe: true,
            lastWillAndTestament: AWSIoTMQTTLastWillAndTestament()
        )
        AWSIoTDataManager.register(with: iotDataConfiguration!,
                                   with: mqttConfig,
                                   forKey: config.awsIoTDataManagerKey)
        
        iotManager = AWSIoTManager.default()
        iot = AWSIoT.default()
        
        iotDataManager = AWSIoTDataManager(forKey: config.awsIoTDataManagerKey)
    }
    
    private func getAWSClientID(credentials: AWSCognitoCredentialsProvider?,
                                completion: @escaping (_ clientId: String?, _ error: Error? ) -> Void) {
        credentials?.getIdentityId().continueWith(block: { (task: AWSTask<NSString>) -> Any? in
            if let error = task.error as NSError? {
                print("AWS Failed to get client ID: \(error)")
                completion(nil, error)
                return nil
            }
            
            guard let clientId = task.result as? String else {
                print("AWS Invalid Client ID")
                completion(nil, nil)
                return nil
            }
            print("AWS Сlient ID: \(clientId)")
            completion(clientId, nil)
            return nil
        })
    }
    
    func setClientId(id: String, withConnect: Bool) {
        clientId = id
        initializeDataPlane(credentialsProvider: self.credentialsProvider)
        if withConnect {
            handleConnectViaWebsocket()
        }
    }
}

extension AWSManager {
    
    private func mqttEventCallback(_ status: AWSIoTMQTTStatus) {
        let backgroundQueue = DispatchQueue(label: "background_queue", qos: .background)
                
        backgroundQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            switch status {
            case .connecting:
                print("AWS Connecting")
            case .connected:
                print("AWS Connected")
                self.registered = true
            case .disconnected:
                if self.needToReconnect {
                    self.handleConnectViaWebsocket()
                }
                print("AWS Disconnected")
            case .connectionRefused:
                print("AWS Connection Refused")
            case .connectionError:
                print("AWS Connection Error")
            case .protocolError:
                print("AWS Protocol Error")
            default:
                print("AWS unknown state: \(status.rawValue)")
            }
        }
    }
    
    // TODO: set siteId
    func handleConnectViaWebsocket() {
        guard !clientId.isEmpty else {
            // MARK: Use in project before handleConnectViaWebsocket
            getAWSClientID(siteId: siteId ?? "", withConnect: true)
            return
        }
        
        iotDataManager.connectUsingWebSocket(withClientId: clientId,
                                             cleanSession: true,
                                             statusCallback: mqttEventCallback(_:))
        updateTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(updateTime),
                                           repeats: true, block: { [weak self] _ in
            self?.disconnect(reconnect: true)
        })
    }
    
    func disconnect(reconnect: Bool = false) {
        needToReconnect = reconnect
        if !reconnect {
            updateTimer?.invalidate()
            updateTimer = nil
        }
        if let iotDataManager = iotDataManager {
            print("AWS Disconnecting...")

              DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                  iotDataManager.disconnect()
              }
        }
    }
    
    func publish(to topic: String, payloads: [String: Any]) {
        print("AWS Publish payloads: \(payloads)")
        
        do {
            let publishData = try JSONSerialization.data(withJSONObject: payloads)
            if iotDataManager.publishData(publishData,
                                          onTopic: topic,
                                          qoS: .messageDeliveryAttemptedAtLeastOnce,
                                          retain: true) {
                print("AWS Success publish to topic: \(topic)")
            } else {
                print("AWS Error publish")
            }
        }
        catch {
            print("AWS Error converting dictionary into Data")
        }
    }
    
    
    func unsubscribe(from topic: String) {
        iotDataManager.unsubscribeTopic(topic)
    }
    
    func subscribe(with topic: String,
                   serialNumberCompletion: ((Bool?) -> Void)?,
                   messageCompletion: (([String : Any]) -> Void)?) {
        func messageReceived(payload: Data) {
            let payloadDictionary = jsonDataToDict(jsonData: payload)
            print("AWS Message received in topic \(topic): \(payloadDictionary)")
            messageCompletion?(payloadDictionary)
        }
        
        let request = iotDataManager.subscribe(toTopic: topic,
                                               qoS: .messageDeliveryAttemptedAtLeastOnce,
                                               messageCallback: messageReceived)
        serialNumberCompletion?(request)
        if request {
            print("AWS Subscribed to topic: \(topic)")
        } else {
            print("AWS Faied to subscribe to topic: \(topic)")
        }
    }
}

extension AWSManager {
    
    private func jsonDataToDict(jsonData: Data?) -> [String: Any] {
        guard let jsonData = jsonData else {
            return [:]
        }
        do {
            return try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as! [String: Any]
        } catch {
            print(error.localizedDescription)
            return [:]
        }
    }
    
}
