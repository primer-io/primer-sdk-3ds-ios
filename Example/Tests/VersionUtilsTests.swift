//
//  VersionUtilsTests.swift
//  Primer3DS_Tests
//
//  Created by Niall Quinn on 18/10/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import XCTest
@testable import Primer3DS
import ThreeDS_SDK

final class VersionUtilsTests: XCTestCase {

    func test_wrapperVersionNumber() throws {
        XCTAssertEqual(VersionUtils.wrapperSDKVersionNumber, Primer3DSSDKVersion)
    }
    
    func test_3DSVersionNumber() throws {
        XCTAssertEqual(VersionUtils.threeDSSDKVersionNumber, NetceteraSDKVersion)
    }

    func test_3DSMatchesNetcetera() throws {
        guard let netceteraVersion = Bundle(for: ThreeDS2ServiceSDK.self)
            .infoDictionary?["CFBundleShortVersionString"] as? String else {
            XCTFail("Could not locate ThreeDS Bundle")
            return
        }
        
        XCTAssertEqual(netceteraVersion, VersionUtils.threeDSSDKVersionNumber)
    }
}
