//
//  KRClient.swift
//  Pods
//
//  Created by Joshua Park on 9/8/16.
//
//

import UIKit

public enum KRClientSuccessHandler {
    
    case data((_ data: Data, _ response: URLResponse) -> Void)
    case json((_ json: [String: Any], _ response: URLResponse) -> Void)
    case string((_ string: String, _ response: URLResponse) -> Void)
    case response((_ response: URLResponse) -> Void)
    case none
    
}

public enum KRClientFailureHandler {
    
    case failure((_ error: NSError, _ response: URLResponse?) -> Void)
    case response((_ response: URLResponse?) -> Void)
    case none
    
}

let kDEFAULT_API_ID = "com.KRClient.defaultID"

fileprivate class GroupRequestHandler {
    
    let mode: GroupRequestMode
    var position: Position
    var success: (() -> Void)!
    var failure: (() -> Void)!
    var alternative: Request?
    var completion: ((Bool) -> Void)?
    
    init(mode: GroupRequestMode, position: Position, completion: ((Bool) -> Void)?) {
        (self.mode, self.position, self.completion) = (mode, position, completion)
    }
    
}

public enum GroupRequestMode {

    case abort
    case ignore
    case recover
    
}

open class KRClient: NSObject {
    
    open static let shared = KRClient()
    
    open let session: URLSession
    open weak var delegate: KRClientDelegate?
    
    open private(set) var hosts = [String: String]()
    open private(set) var headerFields = [String: [String: String]] ()
    open var timeoutInterval: Double = 20.0
    
    open private(set) var templates = [String: RequestTemplate]()
    
    open var indicatorView: UIView?

    // MARK: - Initializer
    
    public init(sessionConfig: URLSessionConfiguration? = nil, delegateQueue: OperationQueue? = nil) {
        let sessionConfig = sessionConfig ?? URLSessionConfiguration.default
        let delegateQueue = delegateQueue ?? {
            let queue = OperationQueue()
            queue.qualityOfService = .userInitiated
            return queue
        }()
        session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: delegateQueue)
    }
    
    // MARK: - API
    
    open func set(defaultHost: String) {
        var strHost = defaultHost
        if strHost[-1][nil] == "/" { strHost = strHost[nil][-1] }
        
        hosts[kDEFAULT_API_ID] = strHost
    }
    
    open func set(defaultHeaderFields: [String: String]) {
        self.headerFields[kDEFAULT_API_ID] = defaultHeaderFields
    }
    
    open func set(identifier: String, host hostString: String) {
        var strHost = hostString
        if strHost[-1][nil] == "/" { strHost = strHost[nil][-1] }
        
        hosts[identifier] = strHost
    }
    
    open func set(identifier: String, headerFields: [String: String]) {
        self.headerFields[identifier] = headerFields
    }
    
    open func set(defaultTemplate: RequestTemplate) {
        self.templates[kDEFAULT_API_ID] = defaultTemplate
    }
    
    open func set(identifier: String, template: RequestTemplate) {
        self.templates[identifier] = template
    }
    
    private func getQueryString(from parameters: [String: Any]) throws -> String {
        let queryString = "?" + parameters.map({ "\($0)=\($1)" }).joined(separator: "&")
        guard let str = queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { fatalError() }
        return str
    }
    
    // MARK: - URL Request
    
    open func getURLRequest(from baseRequest: URLRequest, parameters: [String: Any]) throws -> URLRequest {
        guard let urlString = baseRequest.url?.absoluteString else {
            let message = "<KRClient> Attempt to make a `URLRequest` from an empty string."
            throw KRClientError.invalidOperation(description: message, location: (file: #file, line: #line))
        }
        
        switch baseRequest.httpMethod ?? "GET" {
        case "POST":
            guard let url = URL(string: urlString) else {
                throw KRClientError.stringToURLConversionFailure(string: urlString)
            }
            var request = URLRequest(url: url)
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            return request
        default:
            let strQuery = try getQueryString(from: parameters)
            guard let url = URL(string: urlString + strQuery) else {
                throw KRClientError.stringToURLConversionFailure(string: urlString + strQuery)
            }
            return URLRequest(url: url)
        }
    }
    
    open func getURLRequest(withID identifier: String = "com.KRClient.defaultID", for api: API, parameters: [String: Any]? = nil) throws -> URLRequest {
        guard let strHost = hosts[identifier] else {
            let message = identifier == kDEFAULT_API_ID ?
                "<KRClient> There is no default host set." :
                "<KRClient> There is no host name set for the identifier: \(identifier)"
            throw KRClientError.invalidOperation(description: message, location: (file: #file, line: #line))
        }
        
        let strProtocol = api.SSL ? "https://" : "http://"
        let strURL = strProtocol + strHost + api.path
        
        var request = try getURLRequest(method: api.method, urlString: strURL, parameters: parameters)
        
        if let headerFields = self.headerFields[identifier] {
            for (key, value) in headerFields {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
    
    open func getURLRequest(method: HTTPMethod, urlString: String, parameters: [String: Any]? = nil) throws -> URLRequest {
        var request: URLRequest = try {
            if let params = parameters {
                switch method {
                case .GET, .HEAD:
                    let strQuery = try getQueryString(from: params)
                    guard let url = URL(string: urlString + strQuery) else {
                        throw KRClientError.stringToURLConversionFailure(string: urlString + strQuery)
                    }
                    return URLRequest(url: url)
                    
                case .POST, .PUT:
                    guard let url = URL(string: urlString) else {
                        throw KRClientError.stringToURLConversionFailure(string: urlString)
                    }
                    var request = URLRequest(url: url)
                    request.httpBody = try JSONSerialization.data(withJSONObject: params)
                    return request
                    
                // TODO: Implementation
                }
            } else {
                guard let url = URL(string: urlString) else {
                    throw KRClientError.stringToURLConversionFailure(string: urlString)
                }
                return URLRequest(url: url)
            }
            }()
        
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        
        return request
    }
    
    // MARK: - Dispatch
    
    open func make(httpRequest method: HTTPMethod, urlString: String, parameters: [String: Any]? = nil, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        do {
            let request = try getURLRequest(method: method, urlString: urlString)
            make(httpRequest: request, successHandler: successHandler, failureHandler: failureHandler)
        } catch {
            if let error = error as? KRClientError {
                print(error.nsError)
            } else {
                print(error)
            }
        }
    }
    
    open func make(httpRequestFor apiIdentifier: String, requestAPI: API, parameters: [String: Any]? = nil, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        do {
            let request = try getURLRequest(withID: apiIdentifier, for: requestAPI)
            make(httpRequest: request, successHandler: successHandler, failureHandler: failureHandler)
        } catch {
            if let error = error as? KRClientError {
                print(error.nsError)
            } else {
                print(error)
            }
        }
    }
    
    open func make(httpRequest urlRequest: URLRequest, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        var request = Request(urlRequest: urlRequest)
        (request.successHandler, request.failureHandler) = (successHandler, failureHandler)
        
        make(httpRequest: request)
    }
    
    open func make(httpRequest request: Request) {
        session.delegateQueue.addOperation { 
            self.make(httpRequest: request, groupRequestHandler: nil)
        }
    }
    
    private func make(httpRequest request: Request, groupRequestHandler: GroupRequestHandler?) {
        var request = request
        
        if request.shouldSetParameters {
            request.setParameters()
        }
        
        let delegateQueue = request.queue ?? DispatchQueue.main
        weak var delegate = self.delegate
        let counter = groupRequestHandler?.position
        
        delegateQueue.sync { delegate?.client(self, willMake: request, at: counter) }
        
        self.session.dataTask(with: request.urlRequest, completionHandler: { (optData, optResponse, optError) in
            delegateQueue.async {
                var alternative: Request?
                
                do {
                    guard let data = optData, optError == nil else { throw optError! }
                    
                    guard let response = optResponse as? HTTPURLResponse else {
                        throw NSError(domain: KRClientError.Domain.response,
                                      code: KRClientError.ErrorCode.unknown,
                                      userInfo: [KRClientError.UserInfoKey.urlResponse: optResponse as Any])
                    }
                    
                    if let validation = request.responseTest?(data, response) {
                        guard validation.error == nil, validation.alternative == nil else {
                            alternative = validation.alternative
                            throw validation.error ?? KRClientError.dataValidationFailure.nsError
                        }
                    }
                    
                    delegate?.client(self, willFinish: request, at: counter, withSuccess: true)
                    
                    switch request.successHandler ?? .none {
                        
                    case .data(let handler):
                        handler(data, response)
                        
                    case .json(let handler):
                        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                            throw KRClientError.dataConversionFailure(type: [String: Any].self)
                        }
                        handler(json, response)
                        
                    case .string(let handler):
                        let encoding: UInt = {
                            if let encodingName = response.textEncodingName {
                                let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
                                return CFStringConvertEncodingToNSStringEncoding(cfEncoding)
                            } else {
                                return String.Encoding.isoLatin1.rawValue
                            }
                        }()
                        
                        guard let string = String(data: data, encoding: String.Encoding(rawValue: encoding)) else {
                            throw KRClientError.dataConversionFailure(type: String.self)
                        }
                        
                        handler(string, optResponse!)
                    case .response(let handler):
                        handler(response)
                    case .none:
                        break
                    }
                    
                    delegate?.client(self, didFinish: request, at: counter, withSuccess: true)
                    
                    groupRequestHandler?.success()
                } catch let error {
                    delegate?.client(self, willFinish: request, at: counter, withSuccess: false)
                    
                    switch request.failureHandler ?? .none {
                        
                    case .failure(let handler):
                        handler(error as NSError, optResponse)
                        
                    case .response(let handler):
                        handler(optResponse)
                        
                    case .none:
                        break
                    }
                    
                    defer {
                        delegate?.client(self, didFinish: request, at: counter, withSuccess: false)

                        if let groupRequestHandler = groupRequestHandler {
                            groupRequestHandler.alternative = alternative
                            groupRequestHandler.failure()
                        } else if let alternative = alternative {
                            print("<KRClient> Attempting to recover from failure (\(alternative.urlRequest)).")
                            
                            self.session.delegateQueue.addOperation {
                                self.make(httpRequest: alternative, groupRequestHandler: nil)
                            }
                        }
                    }
                }
            }
        }).resume()
        
        delegateQueue.sync { delegate?.client(self, didMake: request, at: counter) }
    }
    
    // MARK: - Grouped Requests
    
    open func make(groupHTTPRequests groupRequest: RequestType..., mode: GroupRequestMode = .abort, completion: ((Bool) -> Void)? = nil) {
        session.delegateQueue.addOperation {
            self.dispatch(groupHTTPRequests: groupRequest, mode: mode, completion: completion)
        }
    }
    
    private func dispatch(groupHTTPRequests groupRequest: [RequestType], mode: GroupRequestMode, completion: ((Bool) -> Void)?) {
        let originalReq = groupRequest
        var groupRequest = groupRequest
        var abort = false
        let queue = DispatchQueue.global(qos: .utility)
        
        delegate?.client(self, willBegin: originalReq)
        
        queue.async {
            let sema = DispatchSemaphore(value: 0)
            
            let count = groupRequest.reduce(0) { (i, e) -> Int in
                if e is Request { return i + 1 }
                else { return i + (e as! [Request]).count }
            }
            let counter = Position(index: 0, count: count)
            let handler = GroupRequestHandler(mode: mode, position: counter, completion: completion)
            var completionQueue: DispatchQueue?
            
            reqIter: repeat {
                let req = groupRequest.removeFirst()
                
                if req is Request {
                    handler.success = { sema.signal() }
                    handler.failure = { abort = true; sema.signal() }
                    
                    self.make(httpRequest: req as! Request, groupRequestHandler: handler)
                    
                    completionQueue = (req as! Request).queue ?? DispatchQueue.main
                    
                    handler.position.index += 1
                } else {
                    let reqArr = req as! [Request]
                    
                    let group = DispatchGroup()
                    
                    handler.success = { group.leave() }
                    handler.failure = { abort = true; group.leave() }
                    
                    for r in reqArr {
                        group.enter()
                        
                        self.make(httpRequest: r, groupRequestHandler: handler)
                        
                        handler.position.index += 1
                    }
                    
                    completionQueue = reqArr.last!.queue ?? DispatchQueue.main
                    
                    group.wait()
                    sema.signal()
                }
                
                sema.wait()
                
                guard !abort else {
                    mode: switch mode {
                    case .abort:
                        print("<KRClient> Aborting group requests due to failure.")
                        break reqIter
                    case .ignore:
                        abort = false
                        continue reqIter
                    case .recover:
                        if let recover = handler.alternative {
                            print("<KRClient> Attempting to recover from failure (\(recover.urlRequest)).")
                            completionQueue = nil
                            self.dispatch(groupHTTPRequests: [recover as RequestType] + groupRequest, mode: mode, completion: completion)
                        } else {
                            print("<KRClient> Aborting group requests due to failure.")
                        }
                        break reqIter
                    }
                }
            } while groupRequest.count > 0
            
            if let completionQueue = completionQueue {
                completionQueue.sync { handler.completion?(!abort && groupRequest.isEmpty) }
                
                self.session.delegateQueue.addOperation { self.delegate?.client(self, didFinish: originalReq) }
            }
        }
    }
    
}
