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

private let kDEFAULT_API_ID = "com.KRClient.APIManager.defaultID"

public class KRClient: NSObject {
    
    private static let _sharedInstance = KRClient()
    public static func sharedInstance() -> KRClient { return _sharedInstance }
    
    public let session: NSURLSession
    
    public private(set) var hosts = [String: String]()
    public var timeoutInterval: Double = 20.0

    // MARK: - Initializer
    
    public init(sessionConfig: NSURLSessionConfiguration? = nil, delegateQueue: NSOperationQueue? = nil) {
        let sessionConfig = sessionConfig ?? NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: delegateQueue)
    }
    
    // MARK: - API
    
    public func setDefaultHost(hostString: String) -> Bool {
        var strHost = hostString
        if strHost[-1][nil] == "/" { strHost = strHost[nil][-1] }
        
        hosts[kDEFAULT_API_ID] = strHost
        return true
    }
    
    public func setHost(hostString: String, forIdentifier identifier: String) -> Bool {
        var strHost = hostString
        if strHost[-1][nil] == "/" { strHost = strHost[nil][-1] }
        
        hosts[identifier] = strHost
        return true
    }
    
    // MARK: - URL Request
    
    public func getMutableURLRequest(identifier: String = kDEFAULT_API_ID, api: API) -> NSMutableURLRequest {
        guard let strHost = hosts[identifier] else {
            let message = identifier == kDEFAULT_API_ID ?
                "<APIManager> There is no default host set." :
                "<APIManager> There is no host name set for the identifier: \(identifier)"
            fatalError(message)
        }
        
        let strProtocol = api.SSL ? "https://" : "http://"
        let strURL = strProtocol + strHost + api.path
        
        return getMutableURLRequest(api.method, urlString: strURL)
    }
    
    public func getMutableURLRequest(method: URLMethod, urlString: String) -> NSMutableURLRequest {
        guard let url = NSURL(string: urlString) else {
            fatalError("<APIManager> Couldn't initiate an NSURL instance with URL string: \(urlString)")
        }
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        
        return request
    }
    
    public func makeHTTPRequest(method: URLMethod, urlString: String, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        let request = getMutableURLRequest(method, urlString: urlString)
        makeHTTPRequest(request, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    public func makeHTTPRequest(apiIdentifier: String, requestAPI: API, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        let request = getMutableURLRequest(apiIdentifier, api: requestAPI)
        makeHTTPRequest(request, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    public func makeHTTPRequest(urlRequest: NSURLRequest, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        let request = Request(urlRequest: urlRequest, responseTest: nil)
        makeHTTPRequest(request, successHandler: successHandler, failureHandler: failureHandler)
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
                dispatch_async(dispatch_get_main_queue()) { handler(error: error as! NSError, response: optResponse) }
            }
        }.resume()
    }
    
}