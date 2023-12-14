//
//  ViewController.swift
//  Primer3DS
//
//  Created by EvansPie on 08/03/2021.
//  Copyright (c) 2021 EvansPie. All rights reserved.
//

import Primer3DS
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let primer3DS = Primer3DS(environment: .staging)
        
        do {
            try primer3DS.initializeSDK(apiKey: "")
            _ = try primer3DS.createTransaction(directoryServerId: "", supportedThreeDsProtocolVersions: [""])

            primer3DS.performChallenge(threeDSAuthData: ThreeDSAuth(), 
                                       threeDsAppRequestorUrl: URL(string: ""),
                                       presentOn: self) { (sdkAuthCompletion, err) in
            }
        } catch {
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

class ThreeDSAuth: Primer3DSServerAuthData {
    var acsReferenceNumber: String?
    
    var acsSignedContent: String?
    
    var acsTransactionId: String?
    
    var responseCode: String = "AUTH_SUCCESS"
    
    var transactionId: String?
    
    init() {
        
    }
}

