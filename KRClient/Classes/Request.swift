//
//  Request.swift
//  Pods
//
//  Created by Joshua Park on 9/9/16.
//
//

import UIKit

public typealias URLResponseTest = (_ data: Data, _ response: HTTPURLResponse) -> (error: NSError?, alternative: Request?)

public protocol RequestType { }

public struct RequestTemplate {
    
    public var responseTest: URLResponseTest?
    public var successHandler: KRClientSuccessHandler?
    public var failureHandler: KRClientFailureHandler?
    public var queue: DispatchQueue?
    
    public init() {}
    
    public init(responseTest: URLResponseTest?, successHandler: KRClientSuccessHandler?,
                failureHandler: KRClientFailureHandler?, queue: DispatchQueue?) {
        (self.responseTest, self.successHandler, self.failureHandler, self.queue)
            = (responseTest, successHandler, failureHandler, queue)
    }
    
    public func responseTest(_ responseTest: @escaping URLResponseTest) -> RequestTemplate {
        var req = self
        req.responseTest = responseTest
        return req
    }
    
    public func responseTest(_ responseTest: @escaping (Data, HTTPURLResponse) -> Bool) -> RequestTemplate {
        return convert(responseTest: responseTest)
    }
    
    public func responseTest(_ responseTest: @escaping (Data, HTTPURLResponse) -> NSError?) -> RequestTemplate {
        return convert(responseTest: responseTest)
    }

    public func responseTest(_ responseTest: @escaping (Data, HTTPURLResponse) -> Request?) -> RequestTemplate {
        return convert(responseTest: responseTest)
    }
    
    private func convert(responseTest: @escaping (Data, HTTPURLResponse) -> Any) -> RequestTemplate {
        var req = self
        req.responseTest = {
            switch responseTest($0, $1 as HTTPURLResponse) {
            case let result as Request:
                return (getError(from: ErrorKind.dataFailedToPassValidation), result)
            case let result as NSError:
                return (result, nil)
            case let result as Bool:
                return result ? (nil, nil) : (getError(from: ErrorKind.dataFailedToPassValidation), nil)
            default:
                return (nil, nil)
            }
        }
        return req
    }
    
    public func data(_ function: @escaping (Data) -> Void) -> RequestTemplate {
        return data { (data, _) in function(data) }
    }
    
    public func data(_ completion: @escaping (Data, URLResponse) -> Void) -> RequestTemplate {
        var req = self
        req.successHandler = KRClientSuccessHandler.data(completion)
        return req
    }
    
    public func json(_ function: @escaping (([String: Any]) -> Void)) -> RequestTemplate {
        return json { (json, _) in function(json) }
    }
    
    public func json(_ completion: @escaping ([String: Any], URLResponse) -> Void) -> RequestTemplate {
        var req = self
        req.successHandler = KRClientSuccessHandler.json(completion)
        return req
    }
    
    public func string(_ function: @escaping (String) -> Void) -> RequestTemplate {
        return string { (string, _) in function(string) }
    }
    
    public func string(_ completion: @escaping (String, URLResponse) -> Void) -> RequestTemplate {
        var req = self
        req.successHandler = KRClientSuccessHandler.string(completion)
        return req
    }
    
    public func failure(_ function: @escaping (NSError) -> Void) -> RequestTemplate {
        return failure { (error, _) in function(error) }
    }
    
    public func failure(_ completion: @escaping (NSError, URLResponse?) -> Void) -> RequestTemplate {
        var req = self
        req.failureHandler = KRClientFailureHandler.failure(completion)
        return req
    }
    
    public func handle(on queue: DispatchQueue) -> RequestTemplate {
        var req = self
        req.queue = queue
        return req
    }
    
}

public struct Request: RequestType {
    
    public var urlRequest: URLRequest
    private var parameters: (() -> [String: Any])?
    
    public var shouldSetParameters: Bool { return parameters != nil }
    
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
    
    public init(for api: API, autoclosure: @autoclosure @escaping () -> [String: Any]) throws {
        let urlRequest = try KRClient.shared.getURLRequest(withID: kDEFAULT_API_ID, for: api, parameters: nil)
        (self.urlRequest, self.parameters) = (urlRequest, autoclosure)
    }
    
    public init(for api: API, closure: @escaping () -> [String: Any]) throws {
        let urlRequest = try KRClient.shared.getURLRequest(withID: kDEFAULT_API_ID, for: api, parameters: nil)
        (self.urlRequest, self.parameters) = (urlRequest, closure)
    }

    public init(withID ID: String, for api: API, parameters: [String: Any]? = nil) throws {
        let urlRequest = try KRClient.shared.getURLRequest(withID: ID, for: api, parameters: parameters)
        self.urlRequest = urlRequest
    }
    
    public init(withID ID: String, for api: API, autoclosure: @autoclosure @escaping () -> [String: Any]) throws {
        let urlRequest = try KRClient.shared.getURLRequest(withID: ID, for: api, parameters: nil)
        (self.urlRequest, self.parameters) = (urlRequest, autoclosure)
    }
    
    public init(withID ID: String, for api: API, closure: @escaping () -> [String: Any]) throws {
        let urlRequest = try KRClient.shared.getURLRequest(withID: ID, for: api, parameters: nil)
        (self.urlRequest, self.parameters) = (urlRequest, closure)
    }
    
    public init(method: HTTPMethod, urlString: String, parameters: [String: Any]? = nil) throws {
        let urlRequest = try KRClient.shared.getURLRequest(method: method, urlString: urlString, parameters: parameters)
        self.urlRequest = urlRequest
    }
    
    public init(method: HTTPMethod, urlString: String, autoclosure: @autoclosure @escaping () -> [String: Any]) throws {
        let urlRequest = try KRClient.shared.getURLRequest(method: method, urlString: urlString, parameters: nil)
        (self.urlRequest, self.parameters) = (urlRequest, autoclosure)
    }
    
    public init(method: HTTPMethod, urlString: String, closure: @escaping () -> [String: Any]) throws {
        let urlRequest = try KRClient.shared.getURLRequest(method: method, urlString: urlString, parameters: nil)
        (self.urlRequest, self.parameters) = (urlRequest, closure)
    }
    
    public func responseTest(_ responseTest: @escaping URLResponseTest) -> Request {
        var req = self
        req.responseTest = responseTest
        return req
    }
    
    public func responseTest(_ responseTest: @escaping (Data, HTTPURLResponse) -> Bool) -> Request {
        return convert(responseTest: responseTest)
    }
    
    public func responseTest(_ responseTest: @escaping (Data, HTTPURLResponse) -> NSError?) -> Request {
        return convert(responseTest: responseTest)
    }
    
    public func responseTest(_ responseTest: @escaping (Data, HTTPURLResponse) -> Request?) -> Request {
        return convert(responseTest: responseTest)
    }
    
    private func convert(responseTest: @escaping (Data, HTTPURLResponse) -> Any) -> Request {
        var req = self
        req.responseTest = {
            switch responseTest($0, $1 as HTTPURLResponse) {
            case let result as Request:
                return (getError(from: ErrorKind.dataFailedToPassValidation), result)
            case let result as NSError:
                return (result, nil)
            case let result as Bool:
                return result ? (nil, nil) : (getError(from: ErrorKind.dataFailedToPassValidation), nil)
            default:
                return (nil, nil)
            }
        }
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
    
    public func apply(template: RequestTemplate) -> Request {
        var req = self
        (req.responseTest, req.successHandler, req.failureHandler, req.queue) =
            (template.responseTest, template.successHandler, template.failureHandler, template.queue)
        
        return req
    }
    
    public func apply(templateWithID id: String?) -> Request {
        var req = self
        guard let template = KRClient.shared.templates[id ?? kDEFAULT_API_ID] else {
            fatalError("<KRClient> There are no registered templates with the ID: \(id).")
        }
        
        (req.responseTest, req.successHandler, req.failureHandler, req.queue) =
            (template.responseTest, template.successHandler, template.failureHandler, template.queue)
        
        return req
    }
    
    internal mutating func setParameters() {
        urlRequest = try! KRClient.shared.getURLRequest(from: urlRequest, parameters: parameters!())
        parameters = nil
    }
}

// MARK: - Batch Request

extension Array: RequestType { }

public typealias BatchRequest = Array<Request>

public func &(lhs: Request, rhs: Request) -> BatchRequest {
    return [lhs, rhs]
}

public func &(lhs: Request, rhs: BatchRequest) -> BatchRequest {
    return [lhs] + rhs
}

public func &(lhs: BatchRequest, rhs: Request) -> BatchRequest {
    return lhs + [rhs]
}

public func &(lhs: BatchRequest, rhs: BatchRequest) -> BatchRequest {
    return lhs + rhs
}
