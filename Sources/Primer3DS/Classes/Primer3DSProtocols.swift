import Foundation
import UIKit

public protocol Primer3DSProtocol {
    func initializeSDK(apiKey: String,
                       certificates: [Primer3DSCertificate]?) throws
    func createTransaction(directoryServerNetwork: DirectoryServerNetwork,
                           supportedThreeDsProtocolVersions: [String]) throws -> SDKAuthResult
    func performChallenge(threeDSAuthData: Primer3DSServerAuthData,
                          threeDsAppRequestorUrl: URL?,
                          presentOn viewController: UIViewController,
                          completion: @escaping (Primer3DSCompletion?, Error?) -> Void)
    func getProgressDialog() -> Primer3DSProgressDialogProtocol?
}

@objc public protocol Primer3DSCertificate {
    var cardScheme: String { get }
    var encryptionKey: String { get }
    var rootCertificate: String { get }
}

@objc public protocol Primer3DSSDKGeneratedAuthData {
    var sdkAppId: String { get }
    var sdkTransactionId: String { get }
    var sdkTimeout: Int { get }
    var sdkEncData: String { get }
    var sdkEphemPubKey: String { get }
    var sdkReferenceNumber: String { get }
}

@objc public protocol Primer3DSServerAuthData {
    var acsReferenceNumber: String? { get }
    var acsSignedContent: String? { get }
    var acsTransactionId: String? { get }
    var responseCode: String { get }
    var transactionId: String? { get }
}

@objc public protocol Primer3DSCompletion {
    var sdkTransactionId: String { get }
    var transactionStatus: String { get }
}

@objc public protocol Primer3DSProgressDialogProtocol {
    func show()
    func dismiss()
    var view: UIView? { get }
}
