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

// Recommended use

extension Request {
    static var Lesson1: Request {
        let req = try! Request(for: API(method: .GET, path: "notes"), parameters: ["lesson": 1])
            .apply(templateWithID: nil)
        return req
    }
    
    static var Lesson2: Request {
        let req = try! Request(for: API(method: .GET, path: "notes"), parameters: ["lesson": 2])
            .apply(templateWithID: nil)
        return req
    }
    
    static var Lesson3: Request {
        let req = try! Request(for: API(method: .GET, path: "notes"), parameters: ["lesson": 3])
            .apply(templateWithID: nil)
        return req
    }
    
    static func Lesson4_1(param: @autoclosure @escaping () -> String) -> Request {
        let req = try! Request(for: API(method: .GET, path: "notes"), autoclosure: ["lesson": param()])
            .apply(templateWithID: nil)
        return req
    }
    
    static var Lesson4_2: Request {
        let req = try! Request(for: API(method: .GET, path: "notes"), parameters: ["lesson": "4_2"])
            .apply(templateWithID: nil)
        return req
    }
}

fileprivate extension UIColor {
    convenience init(hexColor: Int) {
        let (r, g, b) = ((hexColor & 0xFF0000) >> 16, (hexColor & 0xFF00) >> 8, hexColor & 0xFF)
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0)
    }
    
    static var green: UIColor {
        return UIColor(hexColor: 0x4BD365)
    }
}

class ViewController: UIViewController, NetworkIndicatorDelegate {
    
    @IBOutlet weak var indicatorView: UIView?
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var label4: UILabel!
    @IBOutlet weak var label5: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        KRClient.shared.set(defaultHost: "play-1194.appspot.com")
        KRClient.shared.set(defaultHeaderFields: [
            "Accept": "text/html",
            "Content-Type": "text/html",
            ])
        KRClient.shared.delegate = self

        let template = RequestTemplate()
            .responseTest({ (_, response) -> Bool in
                return response.statusCode == 200
            })
            .string({ (_, response) in
                print(response.url)
            })
            .failure({ (err, response) in
                print(err, response)
            })
        KRClient.shared.set(defaultTemplate: template)
        
        KRClient.shared.indicatorView = indicatorView
        indicatorView?.removeFromSuperview()
        
        // Checking HEAD..
        KRClient.shared.make(httpRequest: try! Request(method: .HEAD, urlString: "https://httpbin.org/get").data({ (data, response) in
            print("SUCCESS", data, response)
        }).failure({ (error, response) in
            print("FAILURE", error, response)
        }))
        
        // Checking conditional GET...
        var req = try! Request(method: .HEAD, urlString: "http://www.example.com/").data({ (data, response) in
            print("SUCCESS", data, response)
        }).failure({ (error, response) in
            print("FAILURE", error, response)
        })
        req.urlRequest.addValue("Tue, 31 Jan 2017 09:00:00 GMT", forHTTPHeaderField: "If-modified-since")
        
        KRClient.shared.make(httpRequest: req)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func resetAllLabels() {
        for label in [label1, label2, label3, label4, label5] {
            label!.textColor = UIColor.lightGray
            label!.text = "Waiting.."
        }
        
        statusLabel.isHidden = true
    }
    
    func setLabel(for labelID: Int, didFail: Bool = false) {
        let label: UILabel = {
            switch labelID {
            case 1: return label1
            case 2: return label2
            case 3: return label3
            case 4: return label4
            default: return label5
            }
        }()
        
        let order: Int = {
            var count = 1
            for label in [label1, label2, label3, label4, label5] {
                if label!.text!.contains("Finished") { count += 1 }
            }
            return count
        }()
        
        label.textColor = didFail ? UIColor.red : UIColor.green
        label.text = didFail ? "Failed" : "Finished \(order)"
    }

    @IBAction func buttonAction(_ sender: UIButton) {
        resetAllLabels()
        sender.isEnabled = false
        
        // Change groups to your taste
        // To make batch requests, pass a `[Request]` type or use the `&` operator
        let idx = segmentedControl.selectedSegmentIndex
        let mode: GroupRequestMode = idx == 0 ? .abort : idx == 1 ? .ignore : .recover
        var paramValue: String!
        
        let req1 = Request.Lesson1.data { (_, _) in
            self.setLabel(for: 1)
        }.failure { (_, _) in
            print("IT'S RAW!")
        }
        let req2 = Request.Lesson2.data { (_, _) in
            paramValue = "4_1"
            self.setLabel(for: 2)
        }
        var req3 = Request.Lesson3
            .string ({ (_, _) in
                self.setLabel(for: 3)
            })
            .failure({ (_, _) in
                self.setLabel(for: 3, didFail: true)
            })
        
        if mode == .recover {
            req3 = req3.responseTest { (_, response) -> Request? in
                if response.statusCode != 200 {
                    return Request.Lesson4_2.data { (_, _) in
                        self.setLabel(for: 5)
                    }
                }
                return nil
            }
        }
        
        let req4 = Request.Lesson4_1(param: paramValue)
            .data { (_, _) in
                self.setLabel(for: 4)
            }
            .failure({ (_, r) in
                self.setLabel(for: 4, didFail: true)
            })

        KRClient.shared.make(groupHTTPRequests: req1 | req2, req3, req4, mode: mode, completion: { (finished) in
            sender.isEnabled = true
            
            self.statusLabel.isHidden = false
            self.statusLabel.textColor = finished ? UIColor.green : UIColor.red
            self.statusLabel.text = finished ? "All requests are finished." : "Group request was aborted."
        })
    }
    
}

