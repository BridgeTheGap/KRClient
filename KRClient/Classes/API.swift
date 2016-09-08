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
        var strPath = path
        if strPath[0][1] != "/" { strPath = "/" + strPath }
        (self.method, self.path, self.SSL) = (method, strPath, SSL)
    }
    
}

private let kDEFAULT_API_ID = "com.KRClient.APIManager.defaultID"

public class APIManager {
    
    private static let _sharedManager = APIManager()
    public static func sharedManager() -> APIManager { return _sharedManager }
    
    public private(set) var hosts = [String: String]()
    public var timeoutInterval: Double = 20.0
    
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
    
    public func getMutableURLRequest(identifier: String = kDEFAULT_API_ID, api: API) -> NSMutableURLRequest {
        guard let strHost = hosts[identifier] else {
            let message = identifier == kDEFAULT_API_ID ?
                "<APIManager> There is no default host set." :
                "<APIManager> There is no host name set for the identifier: \(identifier)"
            fatalError(message)
        }
        
        let strProtocol = api.SSL ? "https://" : "http://"
        let strURL = strProtocol + strHost + api.path
        
        guard let url = NSURL(string: strURL) else {
            fatalError("<APIManager> Couldn't initiate an NSURL instance with URL string: \(api.path)")
        }
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = api.method.rawValue
        request.timeoutInterval = timeoutInterval
        
        return request
    }
    
}
