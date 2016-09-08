//
//  KRClientError.swift
//  Pods
//
//  Created by Joshua Park on 9/8/16.
//
//

public struct KRClientErrorDomain {
    static let Default = "com.KRClient"
    static let DataValidation = "\(KRClientErrorDomain.Default).dataValidation"
}

public struct KRClientErrorCode {
    static let Unknown = -9999
    static let DataFailedToPassValidation = -10
}

public enum KRClientError: ErrorType {
    case DataFailedToPassValidation(description: String?, failureReason: String?)
}

internal func getErrorFromStruct(errorStruct: KRClientError?) -> NSError {
    if let error = errorStruct {
        switch error {
        case .DataFailedToPassValidation(description: let description, failureReason: let failureReason):
            return NSError(domain: KRClientErrorDomain.DataValidation, code: KRClientErrorCode.DataFailedToPassValidation, userInfo:[
                NSLocalizedDescriptionKey: description ?? "The response data failed to pass validation.",
                NSLocalizedFailureReasonErrorKey: failureReason ?? "Unknown."
                ])
        }
    } else {
        return NSError(domain: KRClientErrorDomain.Default, code: KRClientErrorCode.Unknown, userInfo: [
            NSLocalizedDescriptionKey: "An unknown error has occurred."
            ])

    }
    
}