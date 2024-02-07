//
//  DSSStorageError.swift
//  DSSStorage
//
//  Created by David on 13/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

public enum DSSStorageError: DSSSError {
    case invalid
    
    public var code: Int {
        return 0
    }
    
    public var nsError: NSError {
        let domain = String(describing: type(of: self))
        let error = NSError(domain: domain,
                            code: code,
                            userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
        return error
    }
}
