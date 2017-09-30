//
//  KRClientDelegate.swift
//  KRClient
//
//  Created by Joshua Park on 30/09/2017.
//

import UIKit

public struct Position: CustomStringConvertible {
    
    public var index: Int
    public var count: Int
    
    public var description: String {
        return "\(index + 1) of \(count)"
    }
    
}

public protocol KRClientDelegate: class {
    
    func client(_ client: KRClient, willMake request: Request, at position: Position?)
    func client(_ client: KRClient, didMake request: Request, at position: Position?)
    func client(_ client: KRClient, willFinish request: Request, at position: Position?, withSuccess isSuccess: Bool)
    func client(_ client: KRClient, didFinish request: Request, at position: Position?, withSuccess isSuccess: Bool)
    
    func client(_ client: KRClient, willBegin groupRequest: [RequestType])
    func client(_ client: KRClient, didFinish groupRequest: [RequestType])
    
}
