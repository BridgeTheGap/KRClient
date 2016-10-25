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
    
}

public enum KRClientFailureHandler {
    
    case failure((_ error: NSError, _ response: URLResponse?) -> Void)
    
}

let kDEFAULT_API_ID = "com.KRClient.defaultID"

public struct Position: CustomStringConvertible {
    
    public var index: Int
    public var count: Int
    
    public var description: String {
        return "\(index + 1) of \(count)"
    }
    
}

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

public protocol KRClientDelegate: class {
    
    func client(_ client: KRClient, willMake request: Request, at position: Position?)
    func client(_ client: KRClient, didMake request: Request, at position: Position?)
    func client(_ client: KRClient, willFinish request: Request, at position: Position?, withSuccess isSuccess: Bool)
    func client(_ client: KRClient, didFinish request: Request, at position: Position?, withSuccess isSuccess: Bool)
    
    func client(_ client: KRClient, willBegin groupRequest: [RequestType])
    func client(_ client: KRClient, didFinish groupRequest: [RequestType])
    
}

public protocol NetworkIndicatorDelegate: KRClientDelegate {}

public extension NetworkIndicatorDelegate {
    public func client(_ client: KRClient, willMake request: Request, at index: Position?) {
        if let indicatorView = client.indicatorView, index == nil {
            UIApplication.shared.keyWindow?.addSubview(indicatorView)
        }
    }
    
    public func client(_ client: KRClient, didMake request: Request, at index: Position?) { }
    
    public func client(_ client: KRClient, willFinish request: Request, at index: Position?, withSuccess isSuccess: Bool) { }
    
    public func client(_ client: KRClient, didFinish request: Request, at index: Position?, withSuccess isSuccess: Bool) {
        if index == nil {
            client.indicatorView?.removeFromSuperview()
        }
    }
    
    public func client(_ client: KRClient, willBegin groupRequest: [RequestType]) {
        if let indicatorView = client.indicatorView {
            DispatchQueue.main.async { UIApplication.shared.keyWindow?.addSubview(indicatorView) }
        }
    }
    
    public func client(_ client: KRClient, didFinish groupRequest: [RequestType]) {
        if let indicatorView = client.indicatorView {
            DispatchQueue.main.async { indicatorView.removeFromSuperview() }
        }
    }
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
    
    private func getQueryString(from parameters: [String: Any]) -> String {
        let queryString = "?" + parameters.map({ "\($0)=\($1)" }).joined(separator: "&")
        return URLEscapedString(queryString)
    }
    
    // MARK: - URL Request
    
    open func getURLRequest(from baseRequest: URLRequest, parameters: [String: Any]) throws -> URLRequest {
        guard let urlString = baseRequest.url?.absoluteString else {
            let message = "<KRClient> Attempt to make a `URLRequest` from an empty string."
            throw ErrorKind.invalidOperation(description: message, file: #file, line: #line)
        }
        
        switch baseRequest.httpMethod ?? "GET" {
        case "POST":
            guard let url = URL(string: urlString) else {
                throw ErrorKind.failedToConvertStringToURL(string: urlString)
            }
            var request = URLRequest(url: url)
            request.httpBody = try JSONData(parameters)
            return request
        default:
            let strQuery = getQueryString(from: parameters)
            guard let url = URL(string: urlString + strQuery) else {
                throw ErrorKind.failedToConvertStringToURL(string: urlString + strQuery)
            }
            return URLRequest(url: url)
        }
    }
    
    open func getURLRequest(withID identifier: String = kDEFAULT_API_ID, for api: API, parameters: [String: Any]? = nil) throws -> URLRequest {
        guard let strHost = hosts[identifier] else {
            let message = identifier == kDEFAULT_API_ID ?
                "<KRClient> There is no default host set." :
                "<KRClient> There is no host name set for the identifier: \(identifier)"
            throw ErrorKind.invalidOperation(description: message, file: #file, line: #line)
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
                case .GET:
                    let strQuery = getQueryString(from: params)
                    guard let url = URL(string: urlString + strQuery) else {
                        throw ErrorKind.failedToConvertStringToURL(string: urlString + strQuery)
                    }
                    return URLRequest(url: url)
                    
                case .POST:
                    guard let url = URL(string: urlString) else {
                        throw ErrorKind.failedToConvertStringToURL(string: urlString)
                    }
                    var request = URLRequest(url: url)
                    request.httpBody = try JSONData(params)
                    return request
                    
                // TODO: Implementation
                }
            } else {
                guard let url = URL(string: urlString) else {
                    throw ErrorKind.failedToConvertStringToURL(string: urlString)
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
        } catch let error {
            if let errorStruct = error as? ErrorKind {
                print(getError(from: errorStruct))
            } else {
                print(error)
            }
        }
    }
    
    open func make(httpRequestFor apiIdentifier: String, requestAPI: API, parameters: [String: Any]? = nil, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        do {
            let request = try getURLRequest(withID: apiIdentifier, for: requestAPI)
            make(httpRequest: request, successHandler: successHandler, failureHandler: failureHandler)
        } catch let error {
            if let errorStruct = error as? ErrorKind {
                print(getError(from: errorStruct))
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
                do {
                    guard let data = optData else { throw optError! }
                    
                    let response = optResponse as! HTTPURLResponse
                    let validation = request.responseTest?(data, response) ?? ResponseValidation(predicate: true)
                    
                    guard validation.didSucceed else {
                        let error = ErrorKind.dataFailedToPassValidation(description: validation.description,
                                                                         failureReason: validation.failureReason)
                        
                        if let alternative = validation.alternative {
                            print("<KRClient> The original request (\(request.urlRequest)) failed.")
                            
                            if let handler = groupRequestHandler {
                                if let failureHandler = request.failureHandler {
                                    if case KRClientFailureHandler.failure(let handler) = failureHandler {
                                        handler(error as NSError, optResponse)
                                    }
                                }
                                
                                handler.failure()
                                handler.alternative = alternative
                            } else {
                                print("<KRClient> Attempting to recover from failure (\(alternative.urlRequest)).")
                                KRClient.shared.make(httpRequest: alternative, groupRequestHandler: nil)
                            }
                            
                            return
                        } else {
                            throw getError(from: error)
                        }
                    }
                    
                    
                    delegate?.client(self, willFinish: request, at: counter, withSuccess: true)
                    
                    guard let successHandler = request.successHandler else { groupRequestHandler?.success(); return }
                    
                    switch request.successHandler! {
                        
                    case .data(let handler):
                        handler(data, optResponse!)
                        
                    case .json(let handler):
                        let json = try JSONDictionary(data)
                        handler(json, optResponse!)
                        
                    case .string(let handler):
                        let encoding: UInt = {
                            if let encodingName = response.textEncodingName {
                                let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString!)
                                return CFStringConvertEncodingToNSStringEncoding(cfEncoding)
                            } else {
                                return String.Encoding.isoLatin1.rawValue
                            }
                        }()
                        
                        guard let string = String(data: data, encoding: String.Encoding(rawValue: encoding)) else {
                            throw getError(from: ErrorKind.dataFailedToConvertToString)
                        }
                        
                        handler(string, optResponse!)
                        
                    }
                    
                    delegate?.client(self, didFinish: request, at: counter, withSuccess: true)
                    
                    groupRequestHandler?.success()
                } catch let error {
                    defer { groupRequestHandler?.failure() }
                    
                    delegate?.client(self, willFinish: request, at: counter, withSuccess: false)
                    
                    guard let failureHandler = request.failureHandler else { return }
                    guard case KRClientFailureHandler.failure(let handler) = failureHandler else { fatalError() }
                    handler(error as NSError, optResponse)
                    
                    delegate?.client(self, didFinish: request, at: counter, withSuccess: false)
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
