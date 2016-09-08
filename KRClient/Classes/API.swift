//
//  API.swift
//  Pods
//
//  Created by Joshua Park on 9/8/16.
//
//

public enum URLMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
}

public struct API {
    
    public var method: URLMethod
    public var path: String
    public var SSL: Bool
    
    public init(method: URLMethod, path: String, SSL: Bool = false) {
        (self.method, self.path, self.SSL) = (method, path, SSL)
    }
    
}

public class APIManager {
    
    private static let _sharedManager = APIManager()
    public static func sharedManager() -> APIManager { return _sharedManager }
    
    public private(set) var baseURL = [String: NSURL]()
    public var timeoutInterval: Double = 20.0
    
    public func setBaseURL(urlString: String, forIdentifier identifier: String) -> Bool {
        var urlString = urlString
        if urlString[-1][nil] != "/" { urlString + "/" }
        
        guard let url = NSURL(string: urlString) else {
            print("<APIManager> Couldn't initiate an NSURL instance with URL string: \(urlString)")
            return false
        }
        
        baseURL[identifier] = NSURL(string: urlString)
        return true
    }
    
    public func getMutableURLRequest(identifier: String, api: API) -> NSMutableURLRequest {
        guard let baseURLString = baseURL[identifier]?.absoluteString else {
            fatalError("<APIManager> There is no URL instance set for the identifier: \(identifier)")
        }
        
        let protocolString = api.SSL ? "https://" : "http://"
        
        var urlString = protocolString + baseURLString + api.path
        if urlString[0][1] == "/" { urlString = urlString[1][nil] }
        
        guard let url = NSURL(string: urlString) else {
            fatalError("<APIManager> Couldn't initiate an NSURL instance with URL string: \(api.path)")
        }
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = api.method.rawValue
        request.timeoutInterval = timeoutInterval
        
        return request
    }
    
}
