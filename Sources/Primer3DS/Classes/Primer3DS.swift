import Foundation
import ThreeDS_SDK
import UIKit

public class Primer3DS: NSObject, Primer3DSProtocol {

    public static var version: String = VersionUtils.wrapperSDKVersionNumber
    public static var threeDsSdkVersion = VersionUtils.threeDSSDKVersionNumber
    
    @available(*, deprecated, message: "use `version` instead")
    public static var hardcodedVersion = VersionUtils.wrapperSDKVersionNumber
    
    public static let threeDsSdkProvider: String = "NETCETERA"
    public static let supportedSchemeId = "A999999999"
    
    public private(set) var environment: Environment
    public var is3DSSanityCheckEnabled: Bool = true
    
    private var sdkCompletion: ((_ netceteraThreeDSCompletion: Primer3DSCompletion?, _ err: Primer3DSError?) -> Void)?
    private var transaction: Transaction?
    
    let sdkProvider: Primer3DSSDKProviderProtocol
        
    public static func application(_ app: UIApplication, 
                                   open url: URL,
                                   options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return ThreeDSSDKAppDelegate.shared.appOpened(url: url)
    }
    
    public static func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        return ThreeDSSDKAppDelegate.shared.appOpened(userActivity: userActivity)
    }
    
    public convenience init(environment: Environment) {
        self.init(sdkProvider: Primer3DSSDKProvider.shared, environment: environment)
    }
    
    init(sdkProvider: Primer3DSSDKProviderProtocol, environment: Environment) {
        self.sdkProvider = sdkProvider
        self.environment = environment
    }
    
    public func initializeSDK(apiKey: String, certificates: [Primer3DSCertificate]? = nil) throws {
        do {
            let configBuilder = ThreeDS_SDK.ConfigurationBuilder()
            try configBuilder.api(key: apiKey)

            // Only override scheme configuration if we're NOT in production
            if environment != .production {
                try configBuilder.log(to: .debug)
                let supportedSchemeIds: [String] = [Self.supportedSchemeId]

                // Loop through all provided certificates (non-prod)
                for certificate in certificates ?? [] {

                    // Choose specialized scheme constructor if available
                    let scheme: Scheme
                    switch certificate.cardScheme.uppercased() {
                    case "VISA":
                        scheme = .visa()
                    case "MASTERCARD":
                        scheme = .mastercard()
                    case "AMEX":
                        scheme = .amex()
                    case "DINERS_CLUB":
                        scheme = .diners()
                    case "JCB":
                        scheme = .jcb()
                    case "CARTES_BANCAIRES":
                        // Netcetera's 3DS SDK calls this "cb()"
                        scheme = .cb()
                    case "UNIONPAY":
                        // Netcetera's 3DS SDK calls this "union()"
                        scheme = .union()
                    default:
                        // Fallback to default scheme constructor if no specialized API exists
                        scheme = Scheme(name: certificate.cardScheme)
                        scheme.ids = supportedSchemeIds
                        scheme.logoImageName = "visa"
                    }

                    // Override encryption and root certificates with values from /configuration response
                    scheme.encryptionKeyValue = certificate.encryptionKey
                    scheme.rootCertificateValues = [certificate.rootCertificate]

                    // Add scheme to the configBuilder
                    try configBuilder.add(scheme)
                }
            }

            // Build configuration and initialize the 3DS SDK
            let configParameters = configBuilder.configParameters()
            try sdkProvider.initialize(
                configParameters: configParameters,
                locale: nil,
                uiCustomization: nil
            )

        } catch {
            let nsErr = error as NSError
            // If the 3DS SDK is already initialized (code 1001), ignore it. Otherwise, re-throw.
            if nsErr.domain == "com.netcetera.ThreeDS-SDK", nsErr.code == 1001 {
                // Continue silently
            } else {
                let err = Primer3DSError.initializationError(error: error, warnings: nil)
                throw err
            }
        }

        // Verify any warnings after initialization
        try self.verifyWarnings()
    }

    private func verifyWarnings() throws {
        if !is3DSSanityCheckEnabled { return }
        
        var sdkWarnings: [Warning] = []
        do {
            sdkWarnings = try sdkProvider.getWarnings()
            
        } catch {
            let err = Primer3DSError.initializationError(error: error, warnings: nil)
            throw err
        }

        let sdkWarningMessages = sdkWarnings.compactMap({ $0.getMessage() })
        
        if !sdkWarningMessages.isEmpty {
            let message = "[\(sdkWarningMessages.joined(separator: " | "))]"
            let err = Primer3DSError.initializationError(error: nil, warnings: message)
            throw err
        }
    }
    
    var fallbackDirectoryServerId: String? {
        guard environment != .production else {
            return nil
        }
        return "A999999999"
    }

    public func createTransaction(directoryServerNetwork: DirectoryServerNetwork,
                                  supportedThreeDsProtocolVersions: [String]) throws -> SDKAuthResult {
        guard let directoryServerId = directoryServerNetwork.directoryServerId ?? fallbackDirectoryServerId else {
            throw Primer3DSError.missingDsRid(cardNetwork: directoryServerNetwork.rawValue)
        }
        guard let maxSupportedThreeDsProtocolVersion = getMaxValidSupportedThreeDSVersion(supportedThreeDsProtocolVersions) else {
            let err = Primer3DSError.unsupportedProtocolVersion(supportedProtocols: supportedThreeDsProtocolVersions)
            throw err
        }

        do {
            transaction = try sdkProvider.createTransaction(
                directoryServerId: directoryServerId,
                messageVersion: maxSupportedThreeDsProtocolVersion)
            let authData = try transaction!.buildThreeDSecureAuthData()
            return SDKAuthResult(authData: authData, 
                                 maxSupportedThreeDsProtocolVersion: maxSupportedThreeDsProtocolVersion)
            
        } catch let error {
            if let error = error as? Primer3DSError {
                throw error
            }
            if let error = error as? NSError {
                let err = Primer3DSError.failedToCreateTransaction(error: error)
                throw err
            }
            throw Primer3DSError.unknown(description: "Transaction failed but an invalid error was provided")
        }
    }
    
    public func performChallenge(
        threeDSAuthData: Primer3DSServerAuthData,
        threeDsAppRequestorUrl: URL?,
        presentOn viewController: UIViewController,
        completion: @escaping (Primer3DSCompletion?, Error?) -> Void
    ) {
        guard let transaction = transaction else {
            let err = Primer3DSError.unknown(description: "Failed to find transaction")
            completion(nil, err)
            return
        }
        
        let challengeParameters = ChallengeParameters(
            threeDSServerTransactionID: threeDSAuthData.transactionId,
            acsTransactionID: threeDSAuthData.acsTransactionId,
            acsRefNumber: threeDSAuthData.acsReferenceNumber,
            acsSignedContent: threeDSAuthData.acsSignedContent)
        
        if let threeDsAppRequestorUrl = threeDsAppRequestorUrl, 
            let transactionId = threeDSAuthData.transactionId,
            !transactionId.isEmpty {
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
            if let transaction = self.transaction {
                try? transaction.close()
            }
            
            let err = Primer3DSError.challengeFailed(error: error)
            completion(nil, err)
            sdkCompletion = nil
            self.cleanup()
        }
    }
        
    internal func getMaxValidSupportedThreeDSVersion(_ supportedThreeDsVersions: [String]) -> String? {
        let uniqueSupportedThreeDsVersions = supportedThreeDsVersions.unique
        let sdkSupportedProtocolVersions = uniqueSupportedThreeDsVersions.filter(
            { $0.compareWithVersion("2.3") == .orderedAscending &&
                ($0.compareWithVersion("2.1") == .orderedDescending || $0.compareWithVersion("2.1") == .orderedSame)
            })
        let orderedSdkSupportedProtocolVersions = sdkSupportedProtocolVersions.sorted(by: {
            $0.compare($1, options: .numeric) == .orderedDescending
        })
        return orderedSdkSupportedProtocolVersions.first
    }
    
    public func cleanup() {
        try? sdkProvider.cleanup()
    }
}

extension Primer3DS: ChallengeStatusReceiver {
    
    public func completed(completionEvent: CompletionEvent) {
        let sdkTransactionId = completionEvent.getSDKTransactionID()
        let authenticationStatus = AuthenticationStatus(rawValue: completionEvent.getTransactionStatus())
        
        if authenticationStatus == .y {
            let netceteraThreeDSCompletion = AuthCompletion(sdkTransactionId: sdkTransactionId, 
                                                            transactionStatus: authenticationStatus.rawValue)
            sdkCompletion?(netceteraThreeDSCompletion, nil)
        } else {
            let err = Primer3DSError.invalidChallengeStatus(status: authenticationStatus.rawValue, 
                                                            sdkTransactionId: sdkTransactionId)
            sdkCompletion?(nil, err)
        }
        
        self.cleanup()
    }
    
    public func protocolError(protocolErrorEvent: ProtocolErrorEvent) {
        let errorMessage = protocolErrorEvent.getErrorMessage()
        
        let err = Primer3DSError.protocolError(
            description: errorMessage.getErrorDescription(),
            code: errorMessage.getErrorCode(),
            type: errorMessage.getErrorMessageType(),
            component: errorMessage.getErrorComponent(),
            transactionId: errorMessage.getTransactionID(),
            protocolVersion: errorMessage.getMessageVersionNumber(),
            details: errorMessage.getErrorDetail())
        sdkCompletion?(nil, err)
        self.cleanup()
    }
    
    public func runtimeError(runtimeErrorEvent: RuntimeErrorEvent) {
        let err = Primer3DSError.runtimeError(
            description: runtimeErrorEvent.getErrorMessage(),
            code: runtimeErrorEvent.getErrorCode())
        sdkCompletion?(nil, err)
        self.cleanup()
    }
    
    public func timedout() {
        let err = Primer3DSError.timeOut
        sdkCompletion?(nil, err)
        self.cleanup()
    }
    
    public func cancelled() {
        let err = Primer3DSError.cancelled
        sdkCompletion?(nil, err)
        self.cleanup()
    }
}
