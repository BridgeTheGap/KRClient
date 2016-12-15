//
//  KRClientError.swift
//  Pods
//
//  Created by Joshua Park on 9/8/16.
//
//

public enum KRClientError: Error {
    
    public struct Domain {
        
        static let `default` = "pod.KRClient"
        static let request = "\(Domain.default).request"
        static let response = "\(Domain.default).response"
        
    }
    
    public struct ErrorCode {
        
        static let unknown = 0
        
        // KRClient operation related errors
        static let invalidOperation = 100
        static let propagatedError = 101
        
        // Request related errors
        static let requestFailure = 200
        static let stringToURLConversionFailure = 201
        
        // Response related errors
        static let dataValidationFailure = 300
        static let dataConversionFailure = 310
        
    }
    
    public struct UserInfoKey {
        
        static let debugSuggestion  = "DebugSuggestion"
        static let errorLocation    = "ErrorLocation"
        static let expectedDataType = "ExpectedDataType"
        static let urlResponse      = "URLResponse"
        
    }
    
    public class Location: NSObject {
        
        public var file: String
        public var line: Int
        public override var description: String { return "\(type(of: self))(\(file):\(line))" }
        
        public init(file: String, line: Int) { (self.file, self.line) = (file, line) }

    }
    
    case unknown
    
    case invalidOperation(description: String?, location: (file: String, line: Int))
    case propagatedError(error: NSError, location: (file: String, line: Int))
    
    case requestFailure(description: String?)
    case stringToURLConversionFailure(string: String)
    
    case dataValidationFailure
    case dataConversionFailure(type: Any)
    
    var nsError: NSError {
        switch self {
        case .unknown:
            return NSError(domain: Domain.default, code: ErrorCode.unknown, userInfo: nil)
            
        case .invalidOperation(description: let description, location: let location):
            return NSError(domain: Domain.default, code: ErrorCode.requestFailure, userInfo: [
                NSLocalizedDescriptionKey: "An invalid operation was attempted.",
                NSLocalizedFailureReasonErrorKey: description ?? "Unknown.",
                UserInfoKey.errorLocation: Location(file: location.0, line: location.1)
                ])
            
        case .propagatedError(error: let error, location: let location):
            return NSError(domain: Domain.default, code: ErrorCode.propagatedError, userInfo: [
                NSUnderlyingErrorKey: error,
                UserInfoKey.errorLocation: Location(file: location.0, line: location.1)
                ])
            
        case .requestFailure(description: let description):
            return NSError(domain: Domain.request, code: ErrorCode.requestFailure, userInfo: [
                NSLocalizedDescriptionKey: "Failed to make an HTTP request.",
                NSLocalizedFailureReasonErrorKey: description ?? "Unknown."
                ])
            
        case .stringToURLConversionFailure(string: let string):
            return NSError(domain: Domain.request, code: ErrorCode.stringToURLConversionFailure, userInfo: [
                NSLocalizedDescriptionKey: "Failed to initialze a URL instance with string: \(string)."
                ])
            
        case .dataValidationFailure:
            return NSError(domain: Domain.response, code: ErrorCode.dataValidationFailure, userInfo:[
                NSLocalizedDescriptionKey: "The response data failed to pass validation.",
                ])
            
        case .dataConversionFailure(type: let type):
            return NSError(domain: Domain.response, code: ErrorCode.dataConversionFailure, userInfo: [
                NSLocalizedDescriptionKey: "The response data failed to convert to appropriate type.",
                UserInfoKey.expectedDataType: type
                ])
        }
    }
    
}
