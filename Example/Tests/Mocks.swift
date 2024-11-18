import Foundation
@testable import Primer3DS
import ThreeDS_SDK

class MockSDKProvider: Primer3DSSDKProviderProtocol {
    
    var warnings: [Warning]?
    
    var transactions: [String: Transaction]?
    
    var onInitializeCalled: ((ConfigParameters, String?, UiCustomization?) throws -> Void)?
    
    var onCleanupCalled: (() -> Void)?
    
    func initialize(configParameters: ConfigParameters, locale: String?, uiCustomization: ThreeDS_SDK.UiCustomization?) throws {
        try onInitializeCalled?(configParameters, locale, uiCustomization)
    }
    
    func getWarnings() throws -> [Warning] {
        return warnings ?? []
    }
    
    func cleanup() throws {
        onCleanupCalled?()
    }
    
    func createTransaction(directoryServerId: String, messageVersion: String) throws -> Transaction {
        guard let transactions = transactions, transactions.keys.contains("\(directoryServerId):\(messageVersion)") else {
            throw Primer3DSError.failedToCreateTransaction(error: NSError())
        }
        return transactions["\(directoryServerId):\(messageVersion)"]!
    }
}

class MockTransaction: Transaction {
    func useBridgingExtension(version: ThreeDS_SDK.BridgingExtensionVersion) {}
    
    let mockAuthRequestParameters = try! AuthenticationRequestParameters(
        sdkTransactionId: "SDKTransactionId",
        deviceData: "DeviceData",
        sdkEphemeralPublicKey: "SDKEphemeralPublicKey",
        sdkAppId: "SDKAppId",
        sdkReferenceNumber: "SDKReferenceNumber",
        messageVersion: "MessageVersion"
    )
    
    var onDoChallengeCalled: ((ChallengeParameters, ChallengeStatusReceiver, Int, UIViewController) throws -> Void)?
    
    func getAuthenticationRequestParameters() throws -> ThreeDS_SDK.AuthenticationRequestParameters {
        return mockAuthRequestParameters
    }
    
    func doChallenge(challengeParameters: ThreeDS_SDK.ChallengeParameters, challengeStatusReceiver: ThreeDS_SDK.ChallengeStatusReceiver, timeOut: Int, inViewController viewController: UIViewController) throws {
        try onDoChallengeCalled?(challengeParameters, challengeStatusReceiver, timeOut, viewController)
    }
    
    class ProgressDialog: ThreeDS_SDK.ProgressDialog {
        func start() {
        }
        
        func stop() {
        }
    }
    
    func getProgressView() throws -> ThreeDS_SDK.ProgressDialog {
        return ProgressDialog()
    }
    
    func close() throws {
    }
}

class MockServerAuthData: Primer3DSServerAuthData {
    
    var acsReferenceNumber: String? = "ASCReferenceNumber"
    
    var acsSignedContent: String? = "ACSSignedContent"
    
    var acsTransactionId: String? = "ASCTransactionId"
    
    var responseCode: String = "ResponseCode"
    
    var transactionId: String? = "TransactionId"
}

class MockCertificate: NSObject, Primer3DSCertificate {
    
    var cardScheme: String
    
    var encryptionKey: String
    
    var rootCertificate: String
    
    init(cardScheme: String, encryptionKey: String, rootCertificate: String) {
        self.cardScheme = cardScheme
        self.encryptionKey = encryptionKey
        self.rootCertificate = rootCertificate
    }
}
