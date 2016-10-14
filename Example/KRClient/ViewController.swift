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
        
//        KRClient.shared.set(defaultHost: "dev-sylvan.knowreapp.com")
//        KRClient.shared.set(defaultHeaderFields: [
//            "User-Agent": "iPad",
//            "Accept": "application/json",
//            "Content-Type": "application/json",
//            ])
//
//        let req = try! Request(method: .GET, urlString: "http://www.naver.com")
//            .responseTest({ (_, _) -> ResponseValidation in
//                print("TESTING")
//                let alt = Request.AppVersion
//                    .json(self.someFunction)
//                return ResponseValidation(predicate: false, alternative: alt)
//            })
//            .json(self.someFunction)
//            .failure({ (_, response) in
//                print("FAILED \(response)")
//            })
//        
//        KRClient.shared.make(httpRequest: req)
        
        KRClient.shared.set(identifier: "website", host: "play-1194.appspot.com/")
        
        let req1 = try! Request(withID: "website", for: API(method: .GET, path: "notes"), parameters: ["lesson": 1])
            .string({ (_, response) in
                print(response.url)
            })
            .failure({ (err, response) in
                print(err, response)
            })
        let req2 = try! Request(withID: "website", for: API(method: .GET, path: "notes"), parameters: ["lesson": 2])
            .string({ (_, response) in
                print(response.url)
            })
            .failure({ (err, response) in
                print(err, response)
            })
        let req3 = try! Request(withID: "website", for: API(method: .GET, path: "notes"), parameters: ["lesson": 3])
            .responseTest({ (_, response) -> ResponseValidation in
                let req5 = try! Request(withID: "website",
                                        for: API(method: .GET, path: "notes"),
                                        parameters: ["lesson": "4_1"])
                    .string({ (_, response) in
                        print(response.url)
                    })
                return ResponseValidation(predicate: response.statusCode == 200, alternative: req5)
            })
            .string({ (_, response) in
                print(response.url)
            })
            .failure({ (err, response) in
                print(err, response)
            })
        let req4 = try! Request(withID: "website", for: API(method: .GET, path: "notes"), parameters: ["lesson": "4_2"])
            .responseTest({ (_, response) -> Bool in
                return response.statusCode == 200
            })
            .string({ (_, response) in
                print(response.url)
            })
            .failure({ (err, response) in
                print(err, response)
            })
        
        KRClient.shared.make(groupHTTPRequests: req1, req2 + req3, req4, mode: .recover)
    }
    
    func someFunction(json: [String: Any]) {
        print("Calling `\(#function)`")
        print(json)
    }
    
    func altFunction() {
        print("Calling `\(#function)`")
        KRClient.shared.make(httpRequest:
            Request.AppVersion
                .json(self.someFunction)
                .handle(on: DispatchQueue.global(qos: .background))
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func buttonAction(_ sender: AnyObject) {
        print("PRESSED")
    }
}

