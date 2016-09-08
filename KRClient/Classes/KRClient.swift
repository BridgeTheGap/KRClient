//
//  KRClient.swift
//  Pods
//
//  Created by Joshua Park on 9/8/16.
//
//

import UIKit

public typealias URLResponseSuccessHandler = (NSData, NSURLResponse) -> Void
public typealias URLResponseFailureHandler = (NSError, NSURLResponse?) -> Void

public struct KRURLResponseHandler {
    
    public static func data(closure: (data: NSData, response: NSURLResponse) -> Void) -> (data: NSData, response: NSURLResponse) -> Void {
        return closure
    }
    
    public static func JSON(closure: (jsonObj: [String: AnyObject], response: NSURLResponse) -> Void) -> (jsonObj: [String: AnyObject], response: NSURLResponse) -> Void {
        return closure
    }
    
    public static func failure(closure: (error: NSError, response: NSURLResponse?) -> Void) -> (error: NSError, response: NSURLResponse?) -> Void {
        return closure
    }
    
}

public typealias ResponseValidation = (validated: Bool, errorStruct: KRClientError?)
public typealias URLResponseValidator = (data: NSData, response: NSHTTPURLResponse) -> ResponseValidation

public struct Request {
    
    public let urlRequest: NSURLRequest
    public let validation: URLResponseValidator
    
    public init(urlRequest: NSURLRequest, validation: URLResponseValidator) {
        (self.urlRequest, self.validation) = (urlRequest, validation)
    }
    
    public init(apiIdentifier: String, requestAPI: API, validation: URLResponseValidator) {
        let urlRequest = APIManager.sharedManager().getMutableURLRequest(apiIdentifier, api: requestAPI)
        (self.urlRequest, self.validation) = (urlRequest, validation)
    }
    
}


public class KRClient: NSObject {
    
    private static let _sharedInstance = KRClient()
    public static func sharedInstance() -> KRClient { return _sharedInstance }
    
    public let session: NSURLSession
    
    public init(sessionConfig: NSURLSessionConfiguration? = nil, delegateQueue: NSOperationQueue? = nil) {
        let sessionConfig = sessionConfig ?? NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: delegateQueue)
    }
    
    public func makeHTTPRequest(apiIdentifier: String, requestAPI: API, successHandler: URLResponseSuccessHandler, failureHandler: URLResponseFailureHandler) {
        let request = APIManager.sharedManager().getMutableURLRequest(apiIdentifier, api: requestAPI)
        makeHTTPRequest(request, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    public func makeHTTPRequest(urlRequest: NSURLRequest, successHandler: URLResponseSuccessHandler, failureHandler: URLResponseFailureHandler) {
        session.dataTaskWithRequest(urlRequest) { (optData, optResponse, optError) in
            if let data = optData {
                dispatch_async(dispatch_get_main_queue()) { successHandler(data, optResponse!) }
            } else {
                dispatch_async(dispatch_get_main_queue()) { failureHandler(optError!, optResponse) }
            }
        }.resume()
    }

    public func makeHTTPRequest(request: Request, successHandler: URLResponseSuccessHandler, failureHandler: URLResponseFailureHandler) {
        session.dataTaskWithRequest(request.urlRequest) { (optData, optResponse, optError) in
            if let data = optData {
                let validation = request.validation(data: data, response: optResponse as! NSHTTPURLResponse)
                
                if validation.validated {
                    dispatch_async(dispatch_get_main_queue()) { successHandler(data, optResponse!) }
                } else {
                    dispatch_async(dispatch_get_main_queue()) { failureHandler(getErrorFromStruct(validation.errorStruct), optResponse!) }
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) { failureHandler(optError!, optResponse) }
            }
        }.resume()
    }
    
}