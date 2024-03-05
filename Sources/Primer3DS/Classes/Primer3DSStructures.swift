
import Foundation
import ThreeDS_SDK

// Exposed structures

public enum Environment: String, Codable {
    case production = "PRODUCTION"
    case staging = "STAGING"
    case sandbox = "SANDBOX"
    case local = "LOCAL"
}

public enum DirectoryServerNetwork: String {
    case masterCard = "MASTERCARD"
    case visa = "VISA"
    case amex = "AMEX"
    case jcb = "JCB"
    case diners = "DINERS_CLUB"
    case discover = "DISCOVER"
    case unionpay = "UNIONPAY"
    case unknown = "UNKNOWN"

    var directoryServerId: String? {
        switch self {
        case .visa:
            DsRidValues.visa
        case .masterCard:
            DsRidValues.mastercard
        case .amex:
            DsRidValues.amex
        case .jcb:
            DsRidValues.jcb
        case .diners, .discover:
            DsRidValues.diners
        case .unionpay:
            DsRidValues.union
        case .unknown:
            nil
        }
    }

    public static func from(cardNetworkIdentifier: String) -> Self {
        Self(rawValue: cardNetworkIdentifier) ?? .unknown
    }
}

@objc internal class SDKAuthData: NSObject, Primer3DSSDKGeneratedAuthData {
    
    var sdkAppId: String
    var sdkTransactionId: String
    var sdkTimeout: Int
    var sdkEncData: String
    var sdkEphemPubKey: String
    var sdkReferenceNumber: String
    
    init(sdkAppId: String, sdkTransactionId: String, sdkTimeout: Int, sdkEncData: String, sdkEphemPubKey: String, sdkReferenceNumber: String) {
        self.sdkAppId = sdkAppId
        self.sdkTransactionId = sdkTransactionId
        self.sdkTimeout = sdkTimeout
        self.sdkEncData = sdkEncData
        self.sdkEphemPubKey = sdkEphemPubKey
        self.sdkEphemPubKey = sdkEphemPubKey
        self.sdkReferenceNumber = sdkReferenceNumber
        super.init()
    }
}

@objc public class SDKAuthResult: NSObject {
    
    static let sdkMaxTimeout: Int = 10
    
    public var authData: Primer3DSSDKGeneratedAuthData
    public var maxSupportedThreeDsProtocolVersion: String
    
    init(authData: Primer3DSSDKGeneratedAuthData, maxSupportedThreeDsProtocolVersion: String) {
        self.authData = authData
        self.maxSupportedThreeDsProtocolVersion = maxSupportedThreeDsProtocolVersion
        super.init()
    }
}

@objc internal class AuthCompletion: NSObject, Primer3DSCompletion {
    public let sdkTransactionId: String
    public let transactionStatus: String
    
    init(sdkTransactionId: String, transactionStatus: String) {
        self.sdkTransactionId = sdkTransactionId
        self.transactionStatus = transactionStatus
    }
}

internal enum AuthenticationStatus: String {
    case y, a, n, u, e
    
    init(rawValue: String) {
        switch rawValue.lowercased() {
        case "y":
            self = AuthenticationStatus.y
        case "a":
            self = AuthenticationStatus.a
        case "n":
            self = AuthenticationStatus.n
        case "u":
            self = AuthenticationStatus.u
        case "e":
            self = AuthenticationStatus.e
        default:
            self = AuthenticationStatus.e
        }
    }
    
    var `description`: String {
        switch self {
        case .y:
            return "Authentication successful"
        case .a:
            return "Authentication attempted"
        case .n:
            return "Authentication failed"
        case .u:
            return "Authentication unavailable"
        case .e:
            return "Error"
        }
    }
    
    var recommendation: AuthenticationRecommendation {
        switch self {
        case .y,
             .a:
            return .proceed
        case .n,
             .e:
            return .stop
        case .u:
            return .merchantDecision
        }
    }
}

internal enum AuthenticationRecommendation {
    case proceed, stop, merchantDecision
}

