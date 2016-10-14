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

let kDEFAULT_API_ID = "com.KRClient.APIManager.defaultID"

private class GroupRequestHandler {
    
    let mode: GroupRequestMode
    var success: (() -> Void)?
    var failure: (() -> Void)?
    var alternative: Request?
    
    init(mode: GroupRequestMode) {
        self.mode = mode
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
    
    open private(set) var hosts = [String: String]()
    open private(set) var headerFields = [String: [String: String]] ()
    open var timeoutInterval: Double = 20.0

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
    
    private func getQueryString(from parameters: [String: Any]) -> String {
        let queryString = "?" + parameters.map({ "\($0)=\($1)" }).joined(separator: "&")
        return URLEscapedString(queryString)
    }
    
    // MARK: - URL Request
    
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
        make(httpRequest: request, groupRequestHandler: nil)
    }
    
    private func make(httpRequest request: Request, groupRequestHandler: GroupRequestHandler?) {
        let delegateQueue = request.queue ?? DispatchQueue.main
        
        self.session.dataTask(with: request.urlRequest, completionHandler: { (optData, optResponse, optError) in
            delegateQueue.async {
                do {
                    guard let data = optData else { throw optError! }
                    
                    let response = optResponse as! HTTPURLResponse
                    let validation = request.responseTest?(data, response) ?? ResponseValidation(predicate: true)
                    
                    guard validation.didSucceed else {
                        if let alternative = validation.alternative {
                            print("<KRClient> The original request (\(request.urlRequest)) failed. Attempting to recover.")
                            groupRequestHandler?.failure?()
                            groupRequestHandler?.alternative = alternative
                            return
                        } else {
                            throw getError(from: ErrorKind.dataFailedToPassValidation(description: validation.description,
                                                                                      failureReason: validation.failureReason))
                        }
                    }
                    
                    guard let successHandler = request.successHandler else { groupRequestHandler?.success?(); return }
                    
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
                    
                    groupRequestHandler?.success?()
                } catch let error {
                    defer { groupRequestHandler?.failure?() }
                    
                    guard let failureHandler = request.failureHandler else { return }
                    guard case KRClientFailureHandler.failure(let handler) = failureHandler else { fatalError() }
                    handler(error as NSError, optResponse)
                }
            }
        }).resume()
    }
    
    // MARK: - Grouped Requests
    
    open func make(groupHTTPRequests groupRequest: Request..., mode: GroupRequestMode = .abort) {
        make(groupHTTPRequests: groupRequest, mode: mode)
    }
    
    private func make(groupHTTPRequests groupRequest: [Request], mode: GroupRequestMode) {
        var groupRequest = groupRequest
        var abort = false
        let queue = DispatchQueue.global(qos: .utility)
        
        queue.async {
            let group = DispatchSemaphore(value: 0)
            
            let handler = GroupRequestHandler(mode: mode)
            handler.success = { group.signal() }
            handler.failure = { abort = true; group.signal() }
            
            reqIter: repeat {
                let req = groupRequest.removeFirst()
                
                self.make(httpRequest: req, groupRequestHandler: handler)
                
                group.wait()
                
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
                            self.make(groupHTTPRequests: [recover] + groupRequest, mode: mode)
                        } else {
                            print("<KRClient> Aborting group requests due to failure.")
                        }
                        break reqIter
                    }
                }

            } while groupRequest.count > 0
        }
    }
    
}
