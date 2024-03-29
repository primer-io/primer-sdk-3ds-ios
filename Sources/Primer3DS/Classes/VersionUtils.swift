//
//  VersionUtils.swift
//  Primer3DS
//
//  Created by Niall Quinn on 17/10/23.
//

import Foundation

struct VersionUtils {
    
    /**
     Returns the version string of the _wrapper_ sdk in the format `"major.minor.patch"`
     
     The version specified as `Primer3DSSDKVersion` in the file `"sources/version.swift"` will be returned.
     */
    static var wrapperSDKVersionNumber: String {
        Primer3DSSDKVersion
    }
    
    /**
     Returns the version string of the _wrapped_ sdk in the format `"major.minor.patch"`
     
     The version specified as `NetceteraSDKVersion` in the file `"sources/version.swift"` will be returned.
     */
    static var threeDSSDKVersionNumber: String {
        NetceteraSDKVersion
    }
}
