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

open class KRClient: NSObject {
    
    open static let shared = KRClient()
    
    open let session: URLSession
    
    open private(set) var hosts = [String: String]()
    open private(set) var headerFields = [String: [String: String]] ()
    open var timeoutInterval: Double = 20.0

    // MARK: - Initializer
    
    public init(sessionConfig: URLSessionConfiguration? = nil, delegateQueue: OperationQueue? = nil) {
        let sessionConfig = sessionConfig ?? URLSessionConfiguration.default
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
    
    open func getURLRequest(for identifier: String = kDEFAULT_API_ID, api: API, parameters: [String: Any]? = nil) throws -> URLRequest {
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
                default:
                    break
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
    
    open func makeHTTPRequest(method: HTTPMethod, urlString: String, parameters: [String: Any]? = nil, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        do {
            let request = try getURLRequest(method: method, urlString: urlString)
            makeHTTPRequest(request, successHandler: successHandler, failureHandler: failureHandler)
        } catch let error {
            if let errorStruct = error as? ErrorKind {
                print(getError(from: errorStruct))
            } else {
                print(error)
            }
        }
    }
    
    open func makeHTTPRequest(for apiIdentifier: String, requestAPI: API, parameters: [String: Any]? = nil, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        do {
            let request = try getURLRequest(for: apiIdentifier, api: requestAPI)
            makeHTTPRequest(request, successHandler: successHandler, failureHandler: failureHandler)
        } catch let error {
            if let errorStruct = error as? ErrorKind {
                print(getError(from: errorStruct))
            } else {
                print(error)
            }
        }
    }
    
    open func makeHTTPRequest(_ urlRequest: URLRequest, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        do {
            let request = try Request(urlRequest: urlRequest, responseTest: nil)
            makeHTTPRequest(request, successHandler: successHandler, failureHandler: failureHandler)
        } catch let error {
            if let errorStruct = error as? ErrorKind {
                print(getError(from: errorStruct))
            } else {
                print(error)
            }
        }
    }

    open func makeHTTPRequest(_ request: Request, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        session.dataTask(with: request.urlRequest, completionHandler: { (optData, optResponse, optError) in
            do {
                guard let data = optData else { throw optError! }
                
                let response = optResponse as! HTTPURLResponse
                let validation = request.responseTest?(data, response) ?? ResponseValidation(predicate: true)
                
                guard validation.didSucceed else {
                    if let recoveryAction = validation.recoveryAction {
                        print("<KRClient> Original request (\(request.urlRequest) failed. Attempting to recover.")
                        recoveryAction(); return
                    } else {
                        throw getError(from: ErrorKind.dataFailedToPassValidation(description: validation.description, failureReason: validation.failureReason))
                    }
                }
                
                switch successHandler {
                    
                case .data(let handler):
                    DispatchQueue.main.async { handler(data, optResponse!) }
                    
                case .json(let handler):
                    let json = try JSONDictionary(data)
                    DispatchQueue.main.async { handler(json, optResponse!) }
                    
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
                    
                    DispatchQueue.main.async { handler(string, optResponse!) }
                }
            } catch let error {
                guard case KRClientFailureHandler.failure(let handler) = failureHandler else { fatalError() }
                DispatchQueue.main.async { handler(error as NSError, optResponse) }
            }
        }) .resume()
    }
    
    open func serialize(HTTPRequests requests: RequestType..., successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        
    }
}
