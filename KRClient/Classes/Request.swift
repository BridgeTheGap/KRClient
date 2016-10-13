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

public protocol ImmutableRequest {
    var urlRequest: URLRequest { get }
    var responseTest: URLResponseTest? { get }
    var successHandler: KRClientSuccessHandler? { get }
    var failureHandler: KRClientFailureHandler? { get }
}

public protocol CompletionModifiable: ImmutableRequest {
    func data(_ completion: @escaping (Data, URLResponse) -> Void) -> ImmutableRequest
    func data(_ function: @escaping (Data) -> Void) -> ImmutableRequest
    func json(_ completion: @escaping ([String: Any], URLResponse) -> Void) -> ImmutableRequest
    func json(_ function: @escaping (([String: Any]) -> Void)) -> ImmutableRequest
    func string(_ completion: @escaping (String, URLResponse) -> Void) -> ImmutableRequest
    func string(_ function: @escaping (String) -> Void) -> ImmutableRequest
}

public protocol ResponseTestable: CompletionModifiable {
    func responseTest(_ responseTest: @escaping URLResponseTest) -> ResponseTestable
    func responseTest(_ responseTest: @escaping (Data, HTTPURLResponse) -> Bool) -> ResponseTestable
}

public struct Request: ResponseTestable {
    
    public let urlRequest: URLRequest
    public var responseTest: URLResponseTest?
    public var successHandler: KRClientSuccessHandler?
    public var failureHandler: KRClientFailureHandler?
    
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
    
    public func responseTest(_ responseTest: @escaping URLResponseTest) -> ResponseTestable {
        var req = Request(urlRequest: urlRequest)
        req.responseTest = responseTest
        return req
    }
    
    public func responseTest(_ responseTest: @escaping (Data, HTTPURLResponse) -> Bool) -> ResponseTestable {
        var req = Request(urlRequest: urlRequest)
        req.responseTest = { ResponseValidation(predicate: responseTest($0, $1 as! HTTPURLResponse),
                                                recoveryAction: nil) }
        return req
    }
    
    public func data(_ completion: @escaping (Data, URLResponse) -> Void) -> ImmutableRequest {
        var req = self
        req.successHandler = KRClientSuccessHandler.data(completion)
        return req
    }
    
    public func data(_ function: @escaping (Data) -> Void) -> ImmutableRequest {
        var req = self
        req.successHandler = KRClientSuccessHandler.data { (data, _) in function(data) }
        return req
    }
    
    public func json(_ completion: @escaping ([String: Any], URLResponse) -> Void) -> ImmutableRequest {
        var req = self
        req.successHandler = KRClientSuccessHandler.json(completion)
        return req
    }
    
    public func json(_ function: @escaping (([String: Any]) -> Void)) -> ImmutableRequest {
        var req = self
        req.successHandler = KRClientSuccessHandler.json { (json, _) in function(json) }
        return req
    }
    
    public func string(_ completion: @escaping (String, URLResponse) -> Void) -> ImmutableRequest {
        var req = self
        req.successHandler = KRClientSuccessHandler.string(completion)
        return req
    }
    
    public func string(_ function: @escaping (String) -> Void) -> ImmutableRequest {
        var req = self
        req.successHandler = KRClientSuccessHandler.string { (string, _) in function(string) }
        return req
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
