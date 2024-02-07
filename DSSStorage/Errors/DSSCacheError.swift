//
//  DSSCacheError.swift
//  DSSStorage
//
//  Created by David on 15/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

public enum DSSCacheError: DSSSError {
    case objectNotFound(key: String)
    case unwrap(varName: String)
    
    public var code: Int {
        switch self {
        case .objectNotFound: return 0
        case .unwrap: return 1
        }
    }
    
    public var localizedDescription: String {
        switch self {
        case .objectNotFound(let key):
            let description = "LOCAL:Object not cached yet".localized
            return "\(description): key = \(key)."
        case .unwrap(let varName):
            let description = "LOCAL:Unable to unwrap variable".localized
            return "\(description): \(varName)"
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
