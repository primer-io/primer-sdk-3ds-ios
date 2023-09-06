import XCTest
import ThreeDS_SDK
@testable import Primer3DS

final class Primer3DSChallengeTests: XCTestCase {
    private var sdkProvider: MockSDKProvider!
    
    var primer3DS: Primer3DS!
    
    override func setUp() {
        super.setUp()
        sdkProvider = MockSDKProvider()
        primer3DS = Primer3DS(sdkProvider: sdkProvider, environment: .sandbox)
    }
    
    override func tearDown() {
        primer3DS = nil
        sdkProvider = nil
        super.tearDown()
    }
    
    // NOTE: We can't test 'completed' (success flow) as it takes a parameter that is a non-open class from the Three_DS SDK with no init
    
    func testSDKPerformChallenge_Cancelled() throws {
        
        let transaction = MockTransaction()
        try setupSDK(withTransaction: transaction)
        
        let viewController = UIViewController()
        
        let expectation = self.expectation(description: "Expect challenge to succeed")
        
        transaction.onDoChallengeCalled = { _, receiver, _, _ in
            receiver.cancelled()
        }
        
        primer3DS.performChallenge(threeDSAuthData: MockServerAuthData(), threeDsAppRequestorUrl: nil, presentOn: viewController, completion: { completion, error in
            let error = error as! Primer3DSError
            switch error {
            case Primer3DSError.cancelled:
                XCTAssertEqual(error.errorId, Primer3DSError.cancelled.errorId)
                break
            default:
                XCTFail()
            }
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSDKPerformChallenge_Timeout() throws {
        
        let transaction = MockTransaction()
        try setupSDK(withTransaction: transaction)
        
        let viewController = UIViewController()
        
        let expectation = self.expectation(description: "Expect challenge to succeed")
        
        transaction.onDoChallengeCalled = { _, receiver, _, _ in
            receiver.timedout()
        }
        
        primer3DS.performChallenge(threeDSAuthData: MockServerAuthData(), threeDsAppRequestorUrl: nil, presentOn: viewController, completion: { completion, error in
            let error = error as! Primer3DSError
            switch error {
            case Primer3DSError.timeOut:
                XCTAssertEqual(error.errorId, Primer3DSError.timeOut.errorId)
                break
            default:
                XCTFail()
            }
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSDKPerformChallenge_RuntimeError() throws {
        
        let transaction = MockTransaction()
        try setupSDK(withTransaction: transaction)
        
        let viewController = UIViewController()
        
        let expectation = self.expectation(description: "Expect challenge to succeed")
        
        let runtimeErrorEvent = RuntimeErrorEvent(errorCode: "RuntimeErrorCode", errorMessage: "RuntimeErrorMessage")
        transaction.onDoChallengeCalled = { _, receiver, _, _ in
            receiver.runtimeError(runtimeErrorEvent: runtimeErrorEvent)
        }
        
        primer3DS.performChallenge(threeDSAuthData: MockServerAuthData(), threeDsAppRequestorUrl: nil, presentOn: viewController, completion: { completion, error in
            let error = error as! Primer3DSError
            switch error {
            case Primer3DSError.runtimeError(let description, let code):
                XCTAssertEqual(error.errorId, Primer3DSError.runtimeError(description: runtimeErrorEvent.getErrorMessage(), code: runtimeErrorEvent.getErrorCode()).errorId)
                XCTAssertEqual(description, runtimeErrorEvent.getErrorMessage())
                XCTAssertEqual(code, runtimeErrorEvent.getErrorCode())
                break
            default:
                XCTFail()
            }
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSDKPerformChallenge_ProtocolError() throws {
        
        let transaction = MockTransaction()
        try setupSDK(withTransaction: transaction)
        
        let viewController = UIViewController()
        
        let expectation = self.expectation(description: "Expect challenge to succeed")
        let errorMessage = ErrorMessage(
            transactionID: "ErrorMessageTransactionId",
            errorCode: "ErrorCode",
            errorDescription: "ErrorDescription",
            errorDetail: "ErrorDetail",
            errorComponent: "ErrorComponent",
            errorMessageType: "ErrorMessageType",
            errorMessageVersionNumber: "ErrorMessageVersionNumber"
        )
        
        transaction.onDoChallengeCalled = { _, receiver, _, _ in
            receiver.protocolError(protocolErrorEvent: ProtocolErrorEvent(sdkTransactionID: "ProtocolErrorSDKTransactionId", errorMessage: errorMessage))
        }
        
        primer3DS.performChallenge(threeDSAuthData: MockServerAuthData(), threeDsAppRequestorUrl: nil, presentOn: viewController, completion: { completion, error in
            let error = error as! Primer3DSError
            switch error {
            case Primer3DSError.protocolError(let description,
                                            let code,
                                            let type,
                                            let component,
                                            let transactionId,
                                            let protocolVersion,
                                            let details):
                XCTAssertEqual(description, errorMessage.getErrorDescription())
                XCTAssertEqual(code, errorMessage.getErrorCode())
                XCTAssertEqual(type, errorMessage.getErrorMessageType())
                XCTAssertEqual(component, errorMessage.getErrorComponent())
                XCTAssertEqual(transactionId, errorMessage.getTransactionID())
                XCTAssertEqual(protocolVersion, protocolVersion)
                XCTAssertEqual(details, errorMessage.getErrorDetail())
                break
            default:
                XCTFail()
            }
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    private func setupSDK(withTransaction transaction: Transaction? = nil) throws {
        let directoryServerId = "DirectoryServerId"
        let protocolVersion = "2.2"
        
        if let transaction = transaction {
            sdkProvider.transactions = ["\(directoryServerId):\(protocolVersion)": transaction]
        }
        
        try primer3DS.initializeSDK(licenseKey: "LicenseKey")
        _ = try primer3DS.createTransaction(directoryServerId: directoryServerId, supportedThreeDsProtocolVersions: [protocolVersion])
    }

}
