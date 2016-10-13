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
        return API(method: .GET, path: "/")
    }
}

extension Request {
    static var AppVersion: Request {
        let api = API(method: .GET, path: "/api/common/v1.0/getAppVersionInfo")
        let params: [String: Any] = ["input": try! JSONString(["type": "product"])!]
        let req = try! Request(for: api, parameters: params)
        
        return req
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        KRClient.shared.set(defaultHost: "dev-sylvan.knowreapp.com")
        KRClient.shared.set(defaultHeaderFields: [
            "User-Agent": "iPad",
            "Accept": "application/json",
            "Content-Type": "application/json",
            ])

        let req = Request.AppVersion
            .responseTest({ (_, response) -> Bool in
                print(response.statusCode)
                return response.statusCode == 200
            })
            .json(self.someFunction)
        
        KRClient.shared.make(httpRequest: req)
    }
    
    func someFunction(json: [String: Any]) {
        print(json)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

