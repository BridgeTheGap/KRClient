//
//  KRClient.swift
//  Pods
//
//  Created by Joshua Park on 9/8/16.
//
//

import UIKit

protocol URLResponseHandler {}

public enum KRClientSuccessHandler {
    
    case data((data: NSData, response: NSURLResponse) -> Void)
    case JSON((json: [String: AnyObject], response: NSURLResponse) -> Void)
    case string((string: String, response: NSURLResponse) -> Void)
    
}

public enum KRClientFailureHandler {
    
    case failure((error: NSError, response: NSURLResponse?) -> Void)
    
}

public typealias ResponseValidation = (validated: Bool, errorStruct: Error?)
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
    
    public func makeHTTPRequest(apiIdentifier: String, requestAPI: API, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        let request = APIManager.sharedManager().getMutableURLRequest(apiIdentifier, api: requestAPI)
        makeHTTPRequest(request, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    public func makeHTTPRequest(urlRequest: NSURLRequest, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        session.dataTaskWithRequest(urlRequest) { (optData, optResponse, optError) in
            do {
                if let data = optData {
                    switch successHandler {
                        
                    case .data(let handler):
                        dispatch_async(dispatch_get_main_queue()) { handler(data: data, response: optResponse!) }
                        
                    case .JSON(let handler):
                        let json = try JSONDictionary(data)
                        dispatch_async(dispatch_get_main_queue()) { handler(json: json, response: optResponse!) }
                        
                    case .string(let handler):
                        guard let string = String(data: data, encoding: NSUTF8StringEncoding) else {
                            throw getErrorFromStruct(Error.DataFailedToConvertToString)
                        }
                        dispatch_async(dispatch_get_main_queue()) { handler(string: string, response: optResponse!) }
                        
                    }
                } else {
                    guard case KRClientFailureHandler.failure(let handler) = failureHandler else { fatalError() }
                    dispatch_async(dispatch_get_main_queue()) { handler(error: optError!, response: optResponse) }
                }
            } catch let error {
                guard case KRClientFailureHandler.failure(let handler) = failureHandler else { fatalError() }
                dispatch_async(dispatch_get_main_queue()) { handler(error: error as! NSError, response: optResponse) }
            }
        }.resume()
    }

    public func makeHTTPRequest(request: Request, successHandler: KRClientSuccessHandler, failureHandler: KRClientFailureHandler) {
        session.dataTaskWithRequest(request.urlRequest) { (optData, optResponse, optError) in
            do {
                if let data = optData {
                    let validation = request.validation(data: data, response: optResponse as! NSHTTPURLResponse)
                    
                    if validation.validated {
                        switch successHandler {
                            
                        case .data(let handler):
                            dispatch_async(dispatch_get_main_queue()) { handler(data: data, response: optResponse!) }
                            
                        case .JSON(let handler):
                            let json = try JSONDictionary(data)
                            dispatch_async(dispatch_get_main_queue()) { handler(json: json, response: optResponse!) }
                            
                        case .string(let handler):
                            guard let string = String(data: data, encoding: NSUTF8StringEncoding) else {
                                throw getErrorFromStruct(Error.DataFailedToConvertToString)
                            }
                            dispatch_async(dispatch_get_main_queue()) { handler(string: string, response: optResponse!) }
                            
                        }
                    } else {
                        guard case KRClientFailureHandler.failure(let handler) = failureHandler else { fatalError() }
                        let error = getErrorFromStruct(validation.errorStruct)
                        dispatch_async(dispatch_get_main_queue()) { handler(error: error, response: optResponse!) }
                    }
                } else {
                    guard case KRClientFailureHandler.failure(let handler) = failureHandler else { fatalError() }
                    dispatch_async(dispatch_get_main_queue()) { handler(error: optError!, response: optResponse) }
                }
            } catch let error {
                guard case KRClientFailureHandler.failure(let handler) = failureHandler else { fatalError() }
                dispatch_async(dispatch_get_main_queue()) { handler(error: error as! NSError, response: optResponse) }
            }
        }.resume()
    }
    
}