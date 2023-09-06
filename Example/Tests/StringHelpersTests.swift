//
//  StringHelpersTests.swift
//  Primer3DS_Tests
//
//  Created by Jack Newcombe on 06/09/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import XCTest
@testable import Primer3DS

final class StringHelpersTests: XCTestCase {
    
    let versionNumber = "2.2"

    func testCompareVersionNumber_Higher() {
        let value = versionNumber.compareWithVersion("2.3")
        XCTAssertEqual(value, .orderedAscending)
    }

    func testCompareVersionNumber_Lower() {
        let value = versionNumber.compareWithVersion("2.1")
        XCTAssertEqual(value, .orderedDescending)
    }

    func testCompareVersionNumber_Same() {
        let value = versionNumber.compareWithVersion("2.2")
        XCTAssertEqual(value, .orderedSame)
    }
    
    func testCompareVersionNumber_Higher_Complex() {
        let value = versionNumber.compareWithVersion("2.2.1")
        XCTAssertEqual(value, .orderedAscending)
    }

    func testCompareVersionNumber_Lower_Complex() {
        let value = versionNumber.compareWithVersion("2.1.9")
        XCTAssertEqual(value, .orderedDescending)
    }
    
    func testCompareVersionNumber_Same_Complex() {
        let value = versionNumber.compareWithVersion("2.2.0")
        XCTAssertEqual(value, .orderedSame)
    }
    
    func testCompareVersionNumber_Same_Complex_Inverted() {
        let value = "2.2.0".compareWithVersion(versionNumber)
        XCTAssertEqual(value, .orderedSame)
    }
}
