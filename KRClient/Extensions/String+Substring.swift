//
//  KRClientConvenience.swift
//  Pods
//
//  Created by Joshua Park on 9/8/16.
//
//

import UIKit

internal extension String {
    
    internal struct Substring {
        var start: Int?
        var string: String
        
        internal subscript(end: Int?) -> String {
            let start = self.start ?? 0
            let end = end ?? string.count
            guard end < 0 ? string.count > start + abs(end) : start < end && end <= string.count else { return "" }
            guard !string.isEmpty else { return string }
            
            let startIndex = start < 0 ? string.index(string.endIndex, offsetBy: start) : string.index(string.startIndex, offsetBy: start)
            let endIndex = end < 0 ? string.index(string.endIndex, offsetBy: end) : string.index(string.startIndex, offsetBy: end)
            
            return startIndex > endIndex ? "" : String(string[startIndex ..< endIndex])
        }
    }
    
    internal subscript(start: Int?) -> Substring {
        return Substring(start: start, string: self)
    }
    
}
