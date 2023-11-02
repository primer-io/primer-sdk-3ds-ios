//
//  Primer3DSProviderSDK.swift
//  Primer3DS
//
//  Created by Evangelos Pittas on 19/5/23.
//

import Foundation
import ThreeDS_SDK
import UIKit

private let _Primer3DSSDKProvider = Primer3DSSDKProvider()
// ⚠️ ThreeDS2ServiceSDK should only be initialized once
private let _threeDS2Service: ThreeDS2Service = ThreeDS2ServiceSDK()

protocol Primer3DSSDKProviderProtocol {
    func initialize(configParameters: ConfigParameters, locale: String?, uiCustomization: UiCustomization?) throws
    func getWarnings() throws -> [Warning]
    func cleanup() throws
    func createTransaction(directoryServerId: String, messageVersion: String) throws -> Transaction
}

internal class Primer3DSSDKProvider: Primer3DSSDKProviderProtocol {
    
    static var shared: Primer3DSSDKProvider {
        return _Primer3DSSDKProvider
    }
    
    private var sdk: ThreeDS2Service { _threeDS2Service }
    
    func initialize(configParameters: ConfigParameters, locale: String?, uiCustomization: UiCustomization?) throws {
        try sdk.initialize(configParameters, locale: locale, uiCustomization: uiCustomization)
    }
    
    func getWarnings() throws -> [Warning] {
        return try sdk.getWarnings()
    }
    
    func cleanup() throws {
        try sdk.cleanup()
    }
    
    func createTransaction(directoryServerId: String, messageVersion: String) throws -> Transaction {
        return try sdk.createTransaction(directoryServerId: directoryServerId, messageVersion: messageVersion)
    }
    
    fileprivate init() {}
}
