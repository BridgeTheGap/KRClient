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
    
    public init(apiIdentifier: String = kDEFAULT_API_ID, requestAPI: API, parameters: [String: AnyObject]? = nil, responseTest: URLResponseTest? = nil) throws {
        let urlRequest = try KRClient.sharedInstance().getMutableURLRequest(apiIdentifier, api: requestAPI, parameters: parameters)
        (self.urlRequest, self.responseTest) = (urlRequest, responseTest)
    }
    
    public init(method: HTTPMethod, urlString: String, parameters: [String: AnyObject]? = nil, responseTest: URLResponseTest? = nil) throws {
        let urlRequest = try KRClient.sharedInstance().getMutableURLRequest(method, urlString: urlString, parameters: parameters)
        (self.urlRequest, self.responseTest) = (urlRequest, responseTest)
    }
}

