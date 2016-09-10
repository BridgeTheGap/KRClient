//
//  KRClient.swift
//  Pods
//
//  Created by Joshua Park on 9/8/16.
//
//

import UIKit

public enum KRClientSuccessHandler {
    
    case data((data: NSData, response: NSURLResponse) -> Void)
    case JSON((json: [String: AnyObject], response: NSURLResponse) -> Void)
    case string((string: String, response: NSURLResponse) -> Void)
    
}

public enum KRClientFailureHandler {
    
    case failure((error: NSError, response: NSURLResponse?) -> Void)
    
}

let kDEFAULT_API_ID = "com.KRClient.APIManager.defaultID"

public class KRClient: NSObject {
    
    private static let _sharedInstance = KRClient()
    public static func sharedInstance() -> KRClient { return _sharedInstance }
    
    public let session: NSURLSession
    
    public private(set) var hosts = [String: String]()
    public private(set) var headerFields = [String: [String: String]] ()
    public var timeoutInterval: Double = 20.0

    // MARK: - Initializer
    
    public init(sessionConfig: NSURLSessionConfiguration? = nil, delegateQueue: NSOperationQueue? = nil) {
        let sessionConfig = sessionConfig ?? NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: delegateQueue)
    }
    
    // MARK: - API
    
    public func setDefaultHost(hostString: String) {
        var strHost = hostString
        if strHost[-1][nil] == "/" { strHost = strHost[nil][-1] }
        
        hosts[kDEFAULT_API_ID] = strHost
    }
    
    public func setDefaultHeaderFields(headerFields: [String: String]) {
        self.headerFields[kDEFAULT_API_ID] = headerFields
    }
    
    public func setHost(hostString: String, forIdentifier identifier: String) {
        var strHost = hostString
        if strHost[-1][nil] == "/" { strHost = strHost[nil][-1] }
        
        hosts[identifier] = strHost
    }
    
    public func setHeaderFields(headerFields: [String: String], forIdentifier identifier: String) {
        self.headerFields[identifier] = headerFields
    }
    
    private func getQueryStringFromParameters(parameters: [String: AnyObject]) -> String {
        let queryString = "?" + parameters.map({ "\($0)=\($1)" }).joinWithSeparator("&")
        return URLEscapedString(queryString)
    }
    
    // MARK: - URL Request
    
    public func getMutableURLRequest(identifier: String = kDEFAULT_API_ID, api: API, parameters: [String: AnyObject]? = nil) throws -> NSMutableURLRequest {
        guard let strHost = hosts[identifier] else {
            let message = identifier == kDEFAULT_API_ID ?
                "<KRClient> There is no default host set." :
                "<KRClient> There is no host name set for the identifier: \(identifier)"
            throw Error.InvalidOperation(description: message, file: #file, line: #line)
        }
        
        let strProtocol = api.SSL ? "https://" : "http://"
        let strURL = strProtocol + strHost + api.path
        
        let request = try getMutableURLRequest(api.method, urlString: strURL, parameters: parameters)
        
        if let headerFields = self.headerFields[identifier] {
            for (key, value) in headerFields {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
    
    public func getMutableURLRequest(method: HTTPMethod, urlString: String, parameters: [String: AnyObject]? = nil) throws -> NSMutableURLRequest {
        let request: NSMutableURLRequest = try {
            if let params = parameters {
                switch method {
                case .GET:
                    let strQuery = getQueryStringFromParameters(params)
                    guard let url = NSURL(string: urlString + strQuery) else {
                        throw Error.FailedToConvertStringToURL(string: urlString + strQuery)
                    }
                    return NSMutableURLRequest(URL: url)
                    
                case .POST:
                    guard let url = NSURL(string: urlString) else {
                        throw Error.FailedToConvertStringToURL(string: urlString)
                    }
                    let request = NSMutableURLRequest(URL: url)
                    request.HTTPBody = try JSONData(params)
                    return request
                    
                // TODO: Implementation
                default:
                    break
                }
            } else {
                guard let url = NSURL(string: urlString) else {
                    throw Error.FailedToConvertStringToURL(string: urlString)
                }
                return NSMutableURLRequest(URL: url)
            }
            }()
        
        request.HTTPMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        
        return request
    }
    
    public func makeHTTPRequest(method: HTTPMethod, urlString: String, parameters: [String: AnyObject]? = nil, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        do {
            let request = try getMutableURLRequest(method, urlString: urlString)
            makeHTTPRequest(request, successHandler: successHandler, failureHandler: failureHandler)
        } catch let error {
            if let errorStruct = error as? Error {
                print(getErrorFromStruct(errorStruct))
            } else {
                print(error)
            }
        }
    }
    
    public func makeHTTPRequest(apiIdentifier: String, requestAPI: API, parameters: [String: AnyObject]? = nil, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        do {
            let request = try getMutableURLRequest(apiIdentifier, api: requestAPI)
            makeHTTPRequest(request, successHandler: successHandler, failureHandler: failureHandler)
        } catch let error {
            if let errorStruct = error as? Error {
                print(getErrorFromStruct(errorStruct))
            } else {
                print(error)
            }
        }
    }
    
    public func makeHTTPRequest(urlRequest: NSURLRequest, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        do {
            let request = try Request(urlRequest: urlRequest, responseTest: nil)
            makeHTTPRequest(request, successHandler: successHandler, failureHandler: failureHandler)
        } catch let error {
            if let errorStruct = error as? Error {
                print(getErrorFromStruct(errorStruct))
            } else {
                print(error)
            }
        }
    }

    public func makeHTTPRequest(request: Request, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        session.dataTaskWithRequest(request.urlRequest) { (optData, optResponse, optError) in
            do {
                guard let data = optData else { throw optError! }
                
                let response = optResponse as! NSHTTPURLResponse
                let validation = request.responseTest?(data: data, response: response) ?? ResponseValidation(predicate: true, errorStruct: nil)
                
                guard validation.didSucceed else { throw getErrorFromStruct(validation.errorStruct) }
                
                switch successHandler {
                    
                case .data(let handler):
                    dispatch_async(dispatch_get_main_queue()) { handler(data: data, response: optResponse!) }
                    
                case .JSON(let handler):
                    let json = try JSONDictionary(data)
                    dispatch_async(dispatch_get_main_queue()) { handler(json: json, response: optResponse!) }
                    
                case .string(let handler):
                    let encoding: UInt = {
                        if let encodingName = response.textEncodingName {
                            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName)
                            return CFStringConvertEncodingToNSStringEncoding(cfEncoding)
                        } else {
                            return NSISOLatin1StringEncoding
                        }
                    }()
                    
                    guard let string = String(data: data, encoding: encoding) else {
                        throw getErrorFromStruct(Error.DataFailedToConvertToString)
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) { handler(string: string, response: optResponse!) }
                }
            } catch let error {
                guard case KRClientFailureHandler.failure(let handler) = failureHandler else { fatalError() }
                dispatch_async(dispatch_get_main_queue()) { handler(error: error as NSError, response: optResponse) }
            }
        }.resume()
    }
    
}