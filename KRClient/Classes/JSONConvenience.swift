//
//  JSONConvenience.swift
//  Pods
//
//  Created by Joshua Park on 9/8/16.
//
//

public func JSONString(object: AnyObject) throws -> String? {
    let data = try NSJSONSerialization.dataWithJSONObject(object, options: [])
    return String(data: data, encoding: NSUTF8StringEncoding)
}

public func JSONData(object: AnyObject) throws -> NSData? {
    return try NSJSONSerialization.dataWithJSONObject(object, options: [])
}

public func URLEscapedString(s: String) -> String {
    return s.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
}

public func JSONDictionary(data: NSData) throws -> [String: AnyObject] {
    return try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! [String: AnyObject]
}

public extension String {
    public func JSONDic() -> [String: AnyObject]? {
        if let data = self.dataUsingEncoding(NSUTF8StringEncoding) {
            if let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data, options: []) {
                return jsonDic as? [String: AnyObject]
            }
        }
        return nil
    }
}

public func sortArray<T: Comparable>(array: [[String: T]], byKey key: String, ascending: Bool) -> [[String: T]] {
    return ascending ? array.sort { return $0[key] < $1[key] } : array.sort { return $0[key] > $1[key] }
}

public func sortArrayInPlace<T: Comparable>(inout array: [[String: T]], byKey key: String, ascending: Bool) {
    ascending ? array.sort { return $0[key] < $1[key] } : array.sort { return $0[key] > $1[key] }
}

public func getSubDictionary<T: Equatable>(key: String, value: T, from object: AnyObject?) -> [String: AnyObject]? {
    if let obj = object as? [[String: AnyObject]] {
        for dic in obj {
            if let v = dic[key] where v is T && v as! T == value {
                return dic
            }
        }
    }
    return nil
}

public func getSubArrayWith<T: Equatable>(value: T, from object: AnyObject?) -> [AnyObject]? {
    if let obj = object as? [[AnyObject]] {
        for array in obj {
            for element in array {
                if let e = element as? T where e == value {
                    return array
                }
            }
        }
    }
    return nil
}

public func assign<T: AnyObject>(inout object: T, value: AnyObject?) -> Bool {
    if let v = value as? T {
        object = v
        return true
    }
    return false
}

public func assign<T: Any>(inout structType: T, value: AnyObject?) -> Bool {
    if let v = value as? T {
        structType = v
        return true
    }
    return false
}

public extension DictionaryLiteralConvertible {
    public func bool(key: String) -> Bool? {
        if let dic = self as? [String: AnyObject] { return dic[key] as? Bool }
        return nil
    }
    
    public func int(key: String) -> Int? {
        if let dic = self as? [String: AnyObject] { return dic[key] as? Int }
        return nil
    }
    
    public func double(key: String) -> Double? {
        if let dic = self as? [String: AnyObject] { return dic[key] as? Double }
        return nil
    }
    
    public func str(key: String) -> String? {
        if let dic = self as? [String: AnyObject] {
            return dic[key] as? String
        }
        return nil
    }
    
    public func nilStr(key: String) -> String? {
        if let dic = self as? [String: AnyObject], let value = dic[key] as? String {
            return value.characters.count > 0 ? value : nil
        }
        return nil
    }
    
    public func dic(key: String) -> [String: AnyObject]? {
        if let dic = self as? [String: AnyObject] {
            return dic[key] as? [String: AnyObject]
        }
        return nil
    }
    
    public func arr(key: String) -> [AnyObject]? {
        if let dic = self as? [String: AnyObject] {
            return dic[key] as? [AnyObject]
        }
        return nil
    }
    
    public func subDic(key: String) -> [[String: AnyObject]]? {
        if let dic = self as? [String: AnyObject] {
            return dic[key] as? [[String: AnyObject]]
        }
        return nil
    }
}

public func ==(lhs: [String: AnyObject], rhs: [String: AnyObject] ) -> Bool {
    return NSDictionary(dictionary: lhs).isEqualToDictionary(rhs)
}

public extension ArrayLiteralConvertible where Element == [String: AnyObject] {
    public func get<T: Equatable>(key: String, value: T) -> [String: AnyObject]? {
        for dic in self as! [[String: AnyObject]] {
            if let v = dic[key] where v is T && v as! T == value {
                return dic
            }
        }
        return nil
    }
    
    public func getWithIndex<T: Equatable>(key: String, value: T) -> (index: Int?, value: [String: AnyObject]?) {
        for (idx, dic) in (self as! [[String: AnyObject]]).enumerate() {
            if let v = dic[key] where v is T && v as! T == value {
                return (idx, dic)
            }
        }
        return (nil, nil)
    }
    
    public func getAll(key: String) -> [AnyObject]? {
        let arraySelf = self as! [[String: AnyObject]]
        let result = arraySelf.reduce([AnyObject]()) {
            if let value = $0.1[key] { return $0.0 + [value] }
            else { return $0.0 }
        }
        return result.count > 0 ? result : nil
    }
}

public extension ArrayLiteralConvertible where Element == [AnyObject] {
    public func get<T: Equatable>(value: T) -> [AnyObject]? {
        for array in self as! [[AnyObject]] {
            for element in array {
                if let e = element as? T where e == value {
                    return array
                }
            }
        }
        return nil
    }
}
