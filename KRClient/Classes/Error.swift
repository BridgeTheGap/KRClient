//
//  KRClientError.swift
//  Pods
//
//  Created by Joshua Park on 9/8/16.
//
//

public struct ErrorDomain {
    static let Default = "com.KRClient"
    static let DataValidation = "\(ErrorDomain.Default).dataValidation"
    static let DataConversion = "\(ErrorDomain.Default).dataConversion"
}

public struct ErrorCode {
    static let Unknown = -9999
    static let DataFailedToPassValidation = -10
    static let DataFailedToConvertToString = -20
}

public enum Error: ErrorType {
    case DataFailedToPassValidation(description: String?, failureReason: String?)
    case DataFailedToConvertToString
}

internal func getErrorFromStruct(errorStruct: Error?) -> NSError {
    if let error = errorStruct {
        switch error {
        case .DataFailedToPassValidation(description: let description, failureReason: let failureReason):
            return NSError(domain: ErrorDomain.DataValidation, code: ErrorCode.DataFailedToPassValidation, userInfo:[
                NSLocalizedDescriptionKey: description ?? "The response data failed to pass validation.",
                NSLocalizedFailureReasonErrorKey: failureReason ?? "Unknown."
                ])
        case .DataFailedToConvertToString:
            return NSError(domain: ErrorDomain.DataConversion, code: ErrorCode.DataFailedToConvertToString, userInfo: [
                NSLocalizedDescriptionKey: "The response data failed to convert to string.",
            ])
        }
    } else {
        return NSError(domain: ErrorDomain.Default, code: ErrorCode.Unknown, userInfo: [
            NSLocalizedDescriptionKey: "An unknown error has occurred."
            ])

    }
    
}