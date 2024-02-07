//
//  URLExtension.swift
//  DSSStorage
//
//  Created by David on 13/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

extension URL {
    init?(fileURLWithPath path: String?) {
        guard let path = path else { return nil }
        self.init(fileURLWithPath: path)
    }
}
