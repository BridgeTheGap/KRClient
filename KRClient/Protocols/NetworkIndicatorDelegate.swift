//
//  NetworkIndicatorDelegate.swift
//  KRClient
//
//  Created by Joshua Park on 30/09/2017.
//

import UIKit

public protocol NetworkIndicatorDelegate: KRClientDelegate {
    var indicatorWindow: UIView? { get }
}

public extension NetworkIndicatorDelegate {
    public func client(_ client: KRClient, willMake request: Request, at index: Position?) {
        if let indicatorView = client.indicatorView, index == nil {
            DispatchQueue.main.async { self.indicatorWindow?.addSubview(indicatorView) }
        }
    }
    
    public func client(_ client: KRClient, didMake request: Request, at index: Position?) { }
    
    public func client(_ client: KRClient, willFinish request: Request, at index: Position?, withSuccess isSuccess: Bool) { }
    
    public func client(_ client: KRClient, didFinish request: Request, at index: Position?, withSuccess isSuccess: Bool) {
        if let indicatorView = client.indicatorView, index == nil {
            DispatchQueue.main.async { indicatorView.removeFromSuperview() }
        }
    }
    
    public func client(_ client: KRClient, willBegin groupRequest: [RequestType]) {
        if let indicatorView = client.indicatorView {
            DispatchQueue.main.async { self.indicatorWindow?.addSubview(indicatorView) }
        }
    }
    
    public func client(_ client: KRClient, didFinish groupRequest: [RequestType]) {
        if let indicatorView = client.indicatorView {
            DispatchQueue.main.async { indicatorView.removeFromSuperview() }
        }
    }
}


