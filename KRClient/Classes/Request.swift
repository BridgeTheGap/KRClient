//
//  Request.swift
//  Pods
//
//  Created by Joshua Park on 9/9/16.
//
//

import UIKit

public typealias URLResponseTest = (_ data: Data, _ response: HTTPURLResponse) -> ResponseValidation

public struct ResponseValidation {
    public let didSucceed: Bool
    public var recoveryAction: (() -> Void)?
    public var description: String?
    public var failureReason: String?
    
    public init(predicate: Bool, recoveryAction: (() -> Void)? = nil) {
        (self.didSucceed, self.recoveryAction) = (predicate, recoveryAction)
    }
    
    public func description(_ description: String) -> ResponseValidation {
        var copy = self
        copy.description = description
        return copy
    }
    
    public func failureReason(_ failureReason: String) -> ResponseValidation {
        var copy = self
        copy.failureReason = failureReason
        return copy
    }
}

public protocol RequestType {}

public struct Request: RequestType {
    
    public let urlRequest: URLRequest
    public var responseTest: URLResponseTest?
    
    public init(urlRequest: URLRequest, responseTest: URLResponseTest? = nil) {
        (self.urlRequest, self.responseTest) = (urlRequest, responseTest)
    }
    
    public init(requestAPI: API, parameters: [String: Any]? = nil, responseTest: URLResponseTest? = nil) throws {
        let urlRequest = try KRClient.shared.getURLRequest(for: kDEFAULT_API_ID, api: requestAPI, parameters: parameters)
        (self.urlRequest, self.responseTest) = (urlRequest, responseTest)
    }
    
    public init(apiIdentifier: String, requestAPI: API, parameters: [String: Any]? = nil, responseTest: URLResponseTest? = nil) throws {
        let urlRequest = try KRClient.shared.getURLRequest(for: apiIdentifier, api: requestAPI, parameters: parameters)
        (self.urlRequest, self.responseTest) = (urlRequest, responseTest)
    }
    
    public init(method: HTTPMethod, urlString: String, parameters: [String: Any]? = nil, responseTest: URLResponseTest? = nil) throws {
        let urlRequest = try KRClient.shared.getURLRequest(method: method, urlString: urlString, parameters: parameters)
        (self.urlRequest, self.responseTest) = (urlRequest, responseTest)
    }
    
    public func responseTest(_ responseTest: @escaping URLResponseTest) -> Request {
        return Request(urlRequest: urlRequest, responseTest: responseTest)
    }
    
}

struct BatchRequest: RequestType {
    let requests: [Request]
    
    init(requests: [Request]) {
        self.requests = requests
    }
}

func +(lhs: Request, rhs: Request) -> BatchRequest {
    return BatchRequest(requests: [lhs, rhs])
}

func +(lhs: Request, rhs: BatchRequest) -> BatchRequest {
    return BatchRequest(requests: [lhs] + rhs.requests)
}

func +(lhs: BatchRequest, rhs: Request) -> BatchRequest {
    return BatchRequest(requests: lhs.requests + [rhs])
}

func +(lhs: BatchRequest, rhs: BatchRequest) -> BatchRequest {
    return BatchRequest(requests: lhs.requests + rhs.requests)
}
