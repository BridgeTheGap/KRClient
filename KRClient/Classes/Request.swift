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
    public var alternative: Request?
    public var description: String?
    public var failureReason: String?
    
    public init(predicate: Bool, alternative: Request? = nil) {
        (self.didSucceed, self.alternative) = (predicate, alternative)
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

public protocol RequestType { }

public struct Request: RequestType {
    
    public let urlRequest: URLRequest
    public var responseTest: URLResponseTest?
    public var successHandler: KRClientSuccessHandler?
    public var failureHandler: KRClientFailureHandler?
    public var queue: DispatchQueue?
    
    public init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
    }
    
    public init(for api: API, parameters: [String: Any]? = nil) throws {
        let urlRequest = try KRClient.shared.getURLRequest(withID: kDEFAULT_API_ID, for: api, parameters: parameters)
        self.urlRequest = urlRequest
    }
    
    public init(withID ID: String, for api: API, parameters: [String: Any]? = nil) throws {
        let urlRequest = try KRClient.shared.getURLRequest(withID: ID, for: api, parameters: parameters)
        self.urlRequest = urlRequest
    }
    
    public init(method: HTTPMethod, urlString: String, parameters: [String: Any]? = nil) throws {
        let urlRequest = try KRClient.shared.getURLRequest(method: method, urlString: urlString, parameters: parameters)
        self.urlRequest = urlRequest
    }
    
    public func responseTest(_ responseTest: @escaping URLResponseTest) -> Request {
        var req = Request(urlRequest: urlRequest)
        req.responseTest = responseTest
        return req
    }
    
    public func responseTest(_ responseTest: @escaping (Data, HTTPURLResponse) -> Bool) -> Request {
        var req = Request(urlRequest: urlRequest)
        req.responseTest = { ResponseValidation(predicate: responseTest($0, $1 as HTTPURLResponse),
                                                alternative: nil) }
        return req
    }
    
    public func data(_ function: @escaping (Data) -> Void) -> Request {
        return data { (data, _) in function(data) }
    }
    
    public func data(_ completion: @escaping (Data, URLResponse) -> Void) -> Request {
        var req = self
        req.successHandler = KRClientSuccessHandler.data(completion)
        return req
    }
    
    public func json(_ function: @escaping (([String: Any]) -> Void)) -> Request {
        return json { (json, _) in function(json) }
    }
    
    public func json(_ completion: @escaping ([String: Any], URLResponse) -> Void) -> Request {
        var req = self
        req.successHandler = KRClientSuccessHandler.json(completion)
        return req
    }
    
    public func string(_ function: @escaping (String) -> Void) -> Request {
        return string { (string, _) in function(string) }
    }

    public func string(_ completion: @escaping (String, URLResponse) -> Void) -> Request {
        var req = self
        req.successHandler = KRClientSuccessHandler.string(completion)
        return req
    }
    
    public func failure(_ function: @escaping (NSError) -> Void) -> Request {
        return failure { (error, _) in function(error) }
    }
    
    public func failure(_ completion: @escaping (NSError, URLResponse?) -> Void) -> Request {
        var req = self
        req.failureHandler = KRClientFailureHandler.failure(completion)
        return req
    }
    
    public func handle(on queue: DispatchQueue) -> Request {
        var req = self
        req.queue = queue
        return req
    }
    
}

public struct BatchRequest: RequestType {
    public let requests: [Request]
    
    public init(requests: [Request]) {
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
