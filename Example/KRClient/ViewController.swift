//
//  ViewController.swift
//  KRClient
//
//  Created by Joshua Park on 09/07/2016.
//  Copyright (c) 2016 Joshua Park. All rights reserved.
//

import UIKit
import KRClient

private struct API_ID {
    static let Google = "google"
}

private struct API_Host {
    static let Google = "www.google.com"
}

extension API {
    static var Maps: API {
        return API(method: .GET, path: "/path/subpath")
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        APIManager.sharedManager().setHost(API_Host.Google, forIdentifier: API_ID.Google)
        
        let api = API.Maps
        
        let req = Request(apiIdentifier: API_ID.Google, requestAPI: api) { (data, response) -> ResponseValidation in
            (response.MIMEType == "application/json", Error.DataFailedToPassValidation(description: "Wrong media type", failureReason: nil))
        }
        
        let success = KRClientSuccessHandler.string { (string, response) in
            print(string)
        }
        let failure = KRClientFailureHandler.failure { (error, response) in
            print(error.localizedDescription)
        }
        
//        KRClient.sharedInstance().makeHTTPRequest(API_ID.Google, requestAPI: api, successHandler: success, failureHandler: failure)
//        KRClient.sharedInstance().makeHTTPRequest(req, successHandler: success, failureHandler: failure)
        KRClient.sharedInstance().makeHTTPRequest(req, successHandler: success, failureHandler: failure)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

