//
//  DSSKeychainError.swift
//  DSSStorage
//
//  Created by David on 13/12/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Security

public enum DSSKeychainError: DSSSError {
    case unwrap(varName: String)
    case notFound
    case invalidClassType
    
    case noData
    case unexpectedValueData
//    case unhandledError(status: OSStatus)
    case keychain(status: OSStatus)
    
    public var code: Int {
        switch self {
        case .unwrap: return 0
        case .notFound: return 1
        case .invalidClassType: return 2
        case .noData: return 3
        case .unexpectedValueData: return 4
        case .keychain(let status): return Int(status)
        }
    }
    
    public var localizedDescription: String {
        switch self {
        case .unwrap(let varName):
            let description = "LOCAL:FailedToUnwrapVariable:".localized
            return "\(description) \(varName)"
        case .notFound: return "LOCAL:NotFound.".localized
        case .invalidClassType: return "LOCAL:ClassTypeNotAllowedInThisContext.".localized
        case .noData: return "LOCAL:ThereIsNoDataAssociatedWithThisClass.".localized
        case .unexpectedValueData: return "LOCAL:UnexpectedPasswordData.".localized
        case .keychain(let status): return (SecCopyErrorMessageString(status, nil) as String?) ?? "Unknown"
        }
    }
    
    public var nsError: NSError {
        let domain = String(describing: type(of: self))
        let error = NSError(domain: domain,
                            code: code,
                            userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
        return error
    }
}
