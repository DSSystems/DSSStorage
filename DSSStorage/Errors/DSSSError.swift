//
//  DSSSError.swift
//  DSSStorage
//
//  Created by David on 13/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

protocol DSSSError: Error {
    var code: Int { get }
    var nsError: NSError { get }
}
