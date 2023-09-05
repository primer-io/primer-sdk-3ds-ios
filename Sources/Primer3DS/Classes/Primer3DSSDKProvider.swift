//
//  Primer3DSProviderSDK.swift
//  Primer3DS
//
//  Created by Evangelos Pittas on 19/5/23.
//

#if canImport(UIKit)
#if canImport(ThreeDS_SDK)

import Foundation
import ThreeDS_SDK
import UIKit

private let _Primer3DSSDKProvider = Primer3DSSDKProvider()
// ⚠️ ThreeDS2ServiceSDK should only be initialized once
private let _threeDS2Service: ThreeDS2Service = ThreeDS2ServiceSDK()

internal class Primer3DSSDKProvider {
    
    static var shared: Primer3DSSDKProvider {
        return _Primer3DSSDKProvider
    }
    
    var sdk: ThreeDS2Service { _threeDS2Service }
    
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

#endif
#endif

