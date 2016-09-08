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
            let startIndex = start ?? 0 < 0 ? string.endIndex.advancedBy(start!) : string.startIndex.advancedBy(start ?? 0)
            let endIndex = end ?? string.characters.count < 0 ? string.endIndex.advancedBy(end!) : string.startIndex.advancedBy(end ?? string.characters.count)
            
            return startIndex > endIndex ? "" : string.substringWithRange(startIndex ..< endIndex)
        }
    }

    public subscript(start: Int?) -> Substring {
        return Substring(start: start, string: self)
    }
    
}