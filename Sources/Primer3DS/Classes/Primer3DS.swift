#if canImport(UIKit)
#if canImport(ThreeDS_SDK)

import ThreeDS_SDK

public class Primer3DS: NSObject, Primer3DSProtocol {
    
    public private(set) var environment: Environment
    public var is3DSSanityCheckEnabled: Bool = true
    public private(set) var isWeakValidationEnabled: Bool = true
    private let sdk: ThreeDS2Service = ThreeDS2ServiceSDK()
    private var sdkCompletion: ((_ netceteraThreeDSCompletion: Primer3DSCompletion?, _ err: Error?) -> Void)?
    private var transaction: Transaction?
    public var version: String? = {
        return Bundle(for: Primer3DS.self).infoDictionary?["CFBundleShortVersionString"] as? String
    }()
    public var threeDsSdkProvider: String = "NETCETERA"
    public var threeDsSdkVersion: String? {
        return try? sdk.getSDKVersion()
    }
    
    public static func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return ThreeDSSDKAppDelegate.shared.appOpened(url: url)
    }
    
    public static func application(_ application: UIApplication,
                                   continue userActivity: NSUserActivity,
                                   restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return ThreeDSSDKAppDelegate.shared.appOpened(userActivity: userActivity)
    }
    
    public init(environment: Environment) {
        self.environment = environment
    }
    
    public func initializeSDK(licenseKey: String, certificates: [Primer3DSCertificate]? = nil, enableWeakValidation: Bool = true) throws {
        do {
            let configBuilder = ThreeDS_SDK.ConfigurationBuilder()
            try configBuilder.license(key: licenseKey)
            
            if enableWeakValidation {
                try configBuilder.weakValidationEnabled(true)
                self.isWeakValidationEnabled = true
            }
            
            if environment != .production {
                try configBuilder.log(to: .debug)
                
                let supportedSchemeIds: [String] = ["A999999999"]
                
                for certificate in certificates ?? [] {
                    let scheme = Scheme(name: certificate.cardScheme)
                    scheme.ids = supportedSchemeIds
                    scheme.encryptionKeyValue = certificate.encryptionKey
                    scheme.rootCertificateValue = certificate.rootCertificate
                    scheme.logoImageName = "visa"
                    try configBuilder.add(scheme)
                }
            }

            let configParameters = configBuilder.configParameters()
            try sdk.initialize(configParameters,
                               locale: nil,
                               uiCustomization: nil)
            
        } catch {
            throw error
        }
    }
    
    private func verifyWarnings(completion: @escaping (Result<Void, Error>) -> Void) {
        if !is3DSSanityCheckEnabled {
            completion(.success(()))
        } else {
            var sdkWarnings: [Warning] = []
            do {
                sdkWarnings = try sdk.getWarnings()
            } catch {
                var userInfo: [String: Any] = [:]
                userInfo[NSUnderlyingErrorKey] = "\((error as NSError).domain):\((error as NSError).code)"
                userInfo.merge((error as NSError).userInfo) { (_, new) in new }
                userInfo[NSLocalizedDescriptionKey] = "Failed to verify device"
                let nsErr = NSError(domain: "Primer3DS", code: 100, userInfo: userInfo)
                completion(.failure(nsErr))
                return
            }
            
            if !sdkWarnings.isEmpty {
                var message = ""
                for warning in sdkWarnings {
                    message += warning.getMessage()
                    message += "\n"
                }
                
                let nsErr = NSError(domain: "Primer3DS", code: 100, userInfo: [NSLocalizedDescriptionKey: message, "warnings": message])
                completion(.failure(nsErr))
            } else {
                completion(.success(()))
            }
        }
    }
    
    public func createTransaction(directoryServerId: String, supportedThreeDsProtocolVersions: [String]) throws -> SDKAuthResult {
        guard let maxSupportedThreeDsProtocolVersion = getMaxValidSupportedThreeDSVersion(supportedThreeDsProtocolVersions) else {
            let nsErr = NSError(domain: "Primer3DS", code: 200, userInfo: [NSLocalizedDescriptionKey: "Failed to find valid 3DS protocol version in \(supportedThreeDsProtocolVersions)"])
            throw nsErr
        }
        
        do {
            transaction = try sdk.createTransaction(
                directoryServerId: directoryServerId,
                messageVersion: maxSupportedThreeDsProtocolVersion)
            let authData = try transaction!.buildThreeDSecureAuthData()
            return SDKAuthResult(authData: authData, maxSupportedThreeDsProtocolVersion: maxSupportedThreeDsProtocolVersion)
            
        } catch {
            var userInfo: [String: Any] = [:]
            userInfo[NSUnderlyingErrorKey] = "\((error as NSError).domain):\((error as NSError).code)"
            userInfo.merge((error as NSError).userInfo) { (_, new) in new }
            userInfo[NSLocalizedDescriptionKey] = "Failed to create transaction"
            let nsErr = NSError(domain: "Primer3DS", code: 100, userInfo: userInfo)
            throw nsErr
        }
    }
    
    @available(swift, obsoleted: 4.0, renamed: "createTransaction(directoryServerId:supportedThreeDsProtocolVersions:)")
    public func createTransaction(directoryServerId: String, protocolVersion: String) throws -> Primer3DSSDKGeneratedAuthData {
        do {
            transaction = try sdk.createTransaction(directoryServerId: directoryServerId, messageVersion: protocolVersion)
            let sdkAuthData = try transaction!.buildThreeDSecureAuthData()
            return sdkAuthData
        } catch {
            var userInfo: [String: Any] = [:]
            userInfo[NSUnderlyingErrorKey] = "\((error as NSError).domain):\((error as NSError).code)"
            userInfo.merge((error as NSError).userInfo) { (_, new) in new }
            userInfo[NSLocalizedDescriptionKey] = "Failed to create transaction"
            let nsErr = NSError(domain: "Primer3DS", code: 100, userInfo: userInfo)
            throw nsErr
        }
    }
    
    public func performChallenge(threeDSAuthData: Primer3DSServerAuthData,
                                 supportedThreeDsProtocolVersions: [String]?,
                                 threeDsAppRequestorUrl: URL?,
                                 presentOn viewController: UIViewController,
                                 completion: @escaping (Primer3DSCompletion?, Error?) -> Void
    ) {
        guard let transaction = transaction else {
            let nsErr = NSError(domain: "Primer3DS", code: 100, userInfo: [NSLocalizedDescriptionKey: "Failed to find transaction"])
            completion(nil, nsErr)
            return
        }
        
        let challengeParameters = ChallengeParameters(
            threeDSServerTransactionID: threeDSAuthData.transactionId,
            acsTransactionID: threeDSAuthData.acsTransactionId,
            acsRefNumber: threeDSAuthData.acsReferenceNumber,
            acsSignedContent: threeDSAuthData.acsSignedContent)
        
        if let threeDsAppRequestorUrl = threeDsAppRequestorUrl, let transactionId = threeDSAuthData.transactionId, !transactionId.isEmpty {
            let queryItems = [URLQueryItem(name: "transID", value: transactionId)]
            if var urlComps = URLComponents(url: threeDsAppRequestorUrl, resolvingAgainstBaseURL: false) {
                urlComps.queryItems = queryItems
                if let url = urlComps.url {
                    challengeParameters.setThreeDSRequestorAppURL(threeDSRequestorAppURL: url.absoluteString)
                }
            }
        }
        
        sdkCompletion = { [weak self] (netceteraThreeDSCompletion, err) in
            if let err = err {
                completion(nil, err)
            } else if let netceteraThreeDSCompletion = netceteraThreeDSCompletion {
                completion(netceteraThreeDSCompletion, nil)
            } else {
                precondition(false, "Should always receive a completion or an error")
            }
            
            self?.sdkCompletion = nil
        }
        
        do {
            try transaction.doChallenge(challengeParameters: challengeParameters,
                                        challengeStatusReceiver: self,
                                        timeOut: 60,
                                        inViewController: viewController)
            
        } catch {
            var userInfo: [String: Any] = [:]
            userInfo[NSUnderlyingErrorKey] = "\((error as NSError).domain):\((error as NSError).code)"
            userInfo.merge((error as NSError).userInfo) { (_, new) in new }
            userInfo[NSLocalizedDescriptionKey] = "Failed to present challenge"
            let nsErr = NSError(domain: "Primer3DS", code: 100, userInfo: userInfo)
            completion(nil, nsErr)
            sdkCompletion = nil
        }
    }
    
    @available(swift, obsoleted: 4.0, renamed: "performChallenge(threeDSAuthData:supportedThreeDsProtocolVersions:threeDsAppRequestorUrl:presentOn:completion:)")
    public func performChallenge(with threeDSecureAuthResponse: Primer3DSServerAuthData, urlScheme: String?, presentOn viewController: UIViewController, completion: @escaping (Primer3DSCompletion?, Error?) -> Void) {
        guard let transaction = transaction else {
            let nsErr = NSError(domain: "Primer3DS", code: 100, userInfo: [NSLocalizedDescriptionKey: "Failed to find transaction"])
            completion(nil, nsErr)
            return
        }
        
        let challengeParameters = ChallengeParameters(
            threeDSServerTransactionID: threeDSecureAuthResponse.transactionId,
            acsTransactionID: threeDSecureAuthResponse.acsTransactionId,
            acsRefNumber: threeDSecureAuthResponse.acsReferenceNumber,
            acsSignedContent: threeDSecureAuthResponse.acsSignedContent)
        
        if let urlScheme = urlScheme, let transactionId = threeDSecureAuthResponse.transactionId, !transactionId.isEmpty {
            challengeParameters.setThreeDSRequestorAppURL(threeDSRequestorAppURL: "\(urlScheme)://appURL?transID=\(transactionId)")
        }
        
        sdkCompletion = { [weak self] (netceteraThreeDSCompletion, err) in
            if let err = err {
                completion(nil, err)
            } else if let netceteraThreeDSCompletion = netceteraThreeDSCompletion {
                completion(netceteraThreeDSCompletion, nil)
            } else {
                // Will never get in here! Assert an error.
            }
            
            self?.sdkCompletion = nil
        }
        
        do {
            try transaction.doChallenge(challengeParameters: challengeParameters,
                                        challengeStatusReceiver: self,
                                        timeOut: 60,
                                        inViewController: viewController)
            
        } catch {
            var userInfo: [String: Any] = [:]
            userInfo[NSUnderlyingErrorKey] = "\((error as NSError).domain):\((error as NSError).code)"
            userInfo.merge((error as NSError).userInfo) { (_, new) in new }
            userInfo[NSLocalizedDescriptionKey] = "Failed to present challenge"
            let nsErr = NSError(domain: "Primer3DS", code: 100, userInfo: userInfo)
            completion(nil, nsErr)
            sdkCompletion = nil
        }
    }
        
    internal func getMaxValidSupportedThreeDSVersion(_ supportedThreeDsVersions: [String]) -> String? {
        let uniqueSupportedThreeDsVersions = supportedThreeDsVersions.unique
        let sdkSupportedProtocolVersions = uniqueSupportedThreeDsVersions.filter({ $0.compareWithVersion("2.3") == .orderedAscending && ($0.compareWithVersion("2.1") == .orderedDescending || $0.compareWithVersion("2.1") == .orderedSame) })
        let orderedSdkSupportedProtocolVersions = sdkSupportedProtocolVersions.sorted(by: { $0.compare($1, options: .numeric) == .orderedDescending })
        return orderedSdkSupportedProtocolVersions.first
    }
}

extension Primer3DS: ChallengeStatusReceiver {
    
    public func completed(completionEvent: CompletionEvent) {
        let sdkTransactionId = completionEvent.getSDKTransactionID()
        let authenticationStatus = AuthenticationStatus(rawValue: completionEvent.getTransactionStatus())
        let netceteraThreeDSCompletion = AuthCompletion(sdkTransactionId: sdkTransactionId, transactionStatus: authenticationStatus.rawValue)
        sdkCompletion?(netceteraThreeDSCompletion, nil)
    }
    
    public func cancelled() {
        let err = NSError(domain: "Primer3DS", code: -4, userInfo: [NSLocalizedDescriptionKey: "3DS canceled"])
        sdkCompletion?(nil, err)
    }
    
    public func timedout() {
        let err = NSError(domain: "Primer3DS", code: -3, userInfo: [NSLocalizedDescriptionKey: "3DS timed out"])
        sdkCompletion?(nil, err)
    }
    
    public func protocolError(protocolErrorEvent: ProtocolErrorEvent) {
        let errorMessage = protocolErrorEvent.getErrorMessage()
        
        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: errorMessage.getErrorDescription(),
            "errorCode": errorMessage.getErrorCode(),
            "errorType": errorMessage.getErrorMessageType(),
            "component": errorMessage.getErrorComponent(),
            "transactionId": errorMessage.getTransactionID(),
            "version": errorMessage.getMessageVersionNumber()
        ]
        
        if let errorDetail = errorMessage.getErrorDetail() {
            userInfo["errorDetails"] = errorDetail
        }
        
        let err = NSError(domain: "Primer3DS", code: Int(errorMessage.getErrorCode()) ?? -1, userInfo: userInfo)
        sdkCompletion?(nil, err)
    }
    
    public func runtimeError(runtimeErrorEvent: RuntimeErrorEvent) {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: "\(runtimeErrorEvent.getErrorMessage())"
        ]
        
        let err = NSError(domain: "Primer3DS", code: Int(runtimeErrorEvent.getErrorCode() ?? "-2") ?? -2, userInfo: userInfo)
        sdkCompletion?(nil, err)
    }
    
}

#endif
#endif
