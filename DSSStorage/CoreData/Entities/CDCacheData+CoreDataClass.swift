//
//  CDCacheData+CoreDataClass.swift
//  DSSStorage
//
//  Created by David on 15/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CDCacheData)
public class CDCacheData: NSManagedObject {
    public enum AttributeKey: String {
        case key, data, expirationDate
    }
}
