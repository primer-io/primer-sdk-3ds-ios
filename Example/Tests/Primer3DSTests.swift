import XCTest
import ThreeDS_SDK
@testable import Primer3DS

final class Primer3DSTests: XCTestCase {
    
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
    
    func testSDKInitialization_Success() throws {
        
        let apiKey = "ApiKey"
        
        // SDK Setup
        let certificate = MockCertificate(cardScheme: "CardScheme", 
                                          encryptionKey: "EncryptionKey",
                                          rootCertificate: "RootCertificate")

        let expectation = self.expectation(description: "Expect initialized configuration with expected values")

        sdkProvider.onInitializeCalled = { config, _, _ in
            XCTAssertEqual(try config.getParamValue(group: nil, paramName: "api-key"), apiKey)
            XCTAssertEqual(try config.getParamValue(group: "schema_ds_ids", paramName: "cardscheme"), Primer3DS.supportedSchemeId)
            XCTAssertEqual(try config.getParamValue(group: "schema_root_public_key", paramName: "cardscheme"), certificate.rootCertificate)
            XCTAssertEqual(try config.getParamValue(group: "schema_public_key", paramName: "cardscheme"), certificate.encryptionKey)
            expectation.fulfill()
        }
        
        try primer3DS.initializeSDK(apiKey: apiKey, certificates: [certificate])

        wait(for: [expectation], timeout: 60.0)
    }
    
    func testSDKVerifyWarnings() throws {
        
        let warnings: [Warning] = [
            Warning(warningId: "1", message: "WarningMessage", severity: .MEDIUM)
        ]
        
        sdkProvider.warnings = warnings
        
        do {
            try primer3DS.initializeSDK(apiKey: "LicenseKey")
        } catch let error as Primer3DSError {
            XCTAssertEqual(error.errorDescription, "Primer3DS SDK init failed with warnings '[WarningMessage]'.")
            XCTAssertEqual(error.errorId, "3ds-sdk-init-failed")
            XCTAssertEqual(error.recoverySuggestion, "If this application is not installed from a trusted source (e.g. a debug version, or used on an simulator), try to set 'PrimerDebugOptions.is3DSSanityCheckEnabled' to false.")
            switch error {
            case .initializationError(_, let warnings):
                XCTAssertEqual(warnings, "[WarningMessage]")
            default:
                XCTFail()
            }
            return
        }
        
        XCTFail()
    }
    
    func testSDKCreateTransaction_Success() throws {
        
        let directoryServerId = "DirectoryServerId"
        let protocolVersion = "2.2"
        
        let transaction = MockTransaction()
        sdkProvider.transactions = ["\(directoryServerId):\(protocolVersion)": transaction]
        
        try primer3DS.initializeSDK(apiKey: "ApiKey")
        let authResult = try primer3DS.createTransaction(directoryServerId: directoryServerId, supportedThreeDsProtocolVersions: [protocolVersion])
        
        XCTAssertEqual(authResult.authData.sdkAppId, transaction.mockAuthRequestParameters.getSDKAppID())
        XCTAssertEqual(authResult.authData.sdkTransactionId, transaction.mockAuthRequestParameters.getSDKTransactionId())
        XCTAssertEqual(authResult.authData.sdkReferenceNumber, transaction.mockAuthRequestParameters.getSDKReferenceNumber())
        XCTAssertEqual(authResult.authData.sdkEphemPubKey, transaction.mockAuthRequestParameters.getSDKEphemeralPublicKey())
        XCTAssertEqual(authResult.authData.sdkEncData, transaction.mockAuthRequestParameters.getDeviceData())
        XCTAssertEqual(authResult.authData.sdkTimeout, SDKAuthResult.sdkMaxTimeout)
    }
    
    func testSDKCleanup_Success() throws {
        
        let expectation = self.expectation(description: "Expect cleanup to be called on SDK provider")
        
        sdkProvider.onCleanupCalled = { expectation.fulfill() }
        
        primer3DS.cleanup()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    
}
