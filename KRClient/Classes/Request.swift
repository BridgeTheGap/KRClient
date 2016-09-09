//
//  Request.swift
//  Pods
//
//  Created by Joshua Park on 9/9/16.
//
//

import UIKit

public typealias URLResponseTest = (data: NSData, response: NSHTTPURLResponse) -> ResponseValidation

public struct ResponseValidation {
    public let didSucceed: Bool
    public let errorStruct: Error?
    
    public init(predicate: Bool, errorStruct: Error?) {
        (self.didSucceed, self.errorStruct) = (predicate, errorStruct)
    }
}

public struct Request {
    
    public let urlRequest: NSURLRequest
    public let responseTest: URLResponseTest?
    
    public init(urlRequest: NSURLRequest, responseTest: URLResponseTest? = nil) {
        (self.urlRequest, self.responseTest) = (urlRequest, responseTest)
    }
    
    public init(apiIdentifier: String, requestAPI: API, responseTest: URLResponseTest? = nil) {
        let urlRequest = KRClient.sharedInstance().getMutableURLRequest(apiIdentifier, api: requestAPI)
        (self.urlRequest, self.responseTest) = (urlRequest, responseTest)
    }
    
}

