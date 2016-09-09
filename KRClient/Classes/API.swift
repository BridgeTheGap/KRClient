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