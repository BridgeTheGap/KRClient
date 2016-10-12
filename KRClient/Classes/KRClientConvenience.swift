//
//  KRClientConvenience.swift
//  Pods
//
//  Created by Joshua Park on 9/8/16.
//
//

import UIKit

public extension String {
    
    struct Substring {
        var start: Int?
        var string: String
        
        public subscript(end: Int?) -> String {
            let start = self.start ?? 0
            let end = end ?? string.characters.count
            guard end < 0 ? string.characters.count > start + abs(end) : start < end && end <= string.characters.count else { return "" }
            
            let startIndex = start < 0 ? string.characters.index(string.endIndex, offsetBy: start) : string.characters.index(string.startIndex, offsetBy: start)
            let endIndex = end < 0 ? string.characters.index(string.endIndex, offsetBy: end) : string.characters.index(string.startIndex, offsetBy: end)
            
            return startIndex > endIndex ? "" : string.substring(with: startIndex ..< endIndex)
        }
    }
    
    public subscript(start: Int?) -> Substring {
        return Substring(start: start, string: self)
    }
    
}
