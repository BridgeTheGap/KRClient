//
//  JSONConvenience.swift
//  Pods
//
//  Created by Joshua Park on 9/8/16.
//
//

public func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

public func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

public func JSONString(_ object: Any) throws -> String? {
    let data = try JSONSerialization.data(withJSONObject: object, options: [])
    return String(data: data, encoding: String.Encoding.utf8)
}

public func JSONData(_ object: Any) throws -> Data? {
    return try JSONSerialization.data(withJSONObject: object, options: [])
}

public func URLEscapedString(_ s: String) -> String {
    return s.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
}

public func JSONDictionary(_ data: Data) throws -> [String: Any] {
    return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
}

public extension String {
    public func JSONDic() -> [String: Any]? {
        if let data = self.data(using: String.Encoding.utf8) {
            if let jsonDic = try? JSONSerialization.jsonObject(with: data, options: []) {
                return jsonDic as? [String: Any]
            }
        }
        return nil
    }
}

func sort<T: Comparable>(array: [[String: T]], byKey key: String, ascending: Bool) -> [[String: T]] {
    return ascending ? array.sorted { return $0[key] < $1[key] } : array.sorted { return $0[key] > $1[key] }
}

func sortInPlace<T: Comparable>(array: inout [[String: T]], byKey key: String, ascending: Bool) {
    if ascending { array.sort { $0[key] < $1[key] } }
    else { array.sort { $0[key] > $1[key] } }
}

//public func getSubDictionary<T: Equatable>(containingKey key: String, value: T, from object: Any?) -> [String: Any]? {
//    if let obj = object as? [[String: Any]] {
//        for dic in obj {
//            if let v = dic[key] , v is T && v as! T == value {
//                return dic
//            }
//        }
//    }
//    return nil
//}
//
//public func getSubArray<T: Equatable>(containing value: T, from object: Any?) -> [Any]? {
//    if let obj = object as? [[Any]] {
//        for array: [Any] in obj {
//            for element in array {
//                if let e = element as? T , e == value {
//                    return array
//                }
//            }
//        }
//    }
//    return nil
//}
//
//public func assign<T: AnyObject>(_ object: inout T, value: AnyObject?) -> Bool {
//    if let v = value as? T {
//        object = v
//        return true
//    }
//    return false
//}
//
//public func assign<T: Any>(_ structType: inout T, value: AnyObject?) -> Bool {
//    if let v = value as? T {
//        structType = v
//        return true
//    }
//    return false
//}

public extension ExpressibleByDictionaryLiteral {
    public func bool(_ key: String) -> Bool? {
        if let dic = self as? [String: Any] { return dic[key] as? Bool }
        return nil
    }
    
    public func int(_ key: String) -> Int? {
        if let dic = self as? [String: Any] { return dic[key] as? Int }
        return nil
    }
    
    public func double(_ key: String) -> Double? {
        if let dic = self as? [String: Any] { return dic[key] as? Double }
        return nil
    }
    
    public func str(_ key: String) -> String? {
        if let dic = self as? [String: Any] {
            return dic[key] as? String
        }
        return nil
    }
    
    public func nilStr(_ key: String) -> String? {
        if let dic = self as? [String: Any], let value = dic[key] as? String {
            return value.characters.count > 0 ? value : nil
        }
        return nil
    }
    
    public func dic(_ key: String) -> [String: Any]? {
        if let dic = self as? [String: Any] {
            return dic[key] as? [String: Any]
        }
        return nil
    }
    
    public func arr(_ key: String) -> [Any]? {
        if let dic = self as? [String: Any] {
            return dic[key] as? [AnyObject]
        }
        return nil
    }
    
    public func dicArr(_ key: String) -> [[String: Any]]? {
        if let dic = self as? [String: Any] {
            return dic[key] as? [[String: Any]]
        }
        return nil
    }
}

//public func ==(lhs: [String: Any], rhs: [String: Any] ) -> Bool {
//    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
//}
//
//public extension ExpressibleByArrayLiteral where Element == [String: Any] {
//    public func get<T: Equatable>(_ key: String, value: T) -> [String: Any]? {
//        for dic in self as! [[String: Any]] {
//            if let v = dic[key] , v is T && v as! T == value {
//                return dic
//            }
//        }
//        return nil
//    }
//    
//    public func getWithIndex<T: Equatable>(_ key: String, value: T) -> (index: Int?, value: [String: Any]?) {
//        for (idx, dic) in (self as! [[String: Any]]).enumerated() {
//            if let v = dic[key] , v is T && v as! T == value {
//                return (idx, dic)
//            }
//        }
//        return (nil, nil)
//    }
//    
//    public func getAll(_ key: String) -> [Any]? {
//        let arraySelf = self as! [[String: Any]]
//        let result = arraySelf.reduce([Any]()) {
//            if let value = $0.1[key] { return $0.0 + [value] }
//            else { return $0.0 }
//        }
//        return result.count > 0 ? result : nil
//    }
//}
//
//public extension ExpressibleByArrayLiteral where Element == [Any] {
//    public func get<T: Equatable>(_ value: T) -> [Any]? {
//        for array in self as! [[Any]] {
//            for element in array {
//                if let e = element as? T , e == value {
//                    return array
//                }
//            }
//        }
//        return nil
//    }
//}
