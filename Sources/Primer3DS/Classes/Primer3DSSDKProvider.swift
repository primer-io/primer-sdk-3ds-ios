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
    
    fileprivate init() {}
}

#endif
#endif

