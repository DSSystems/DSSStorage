//
//  CDCacheData+CoreDataProperties.swift
//  DSSStorage
//
//  Created by David on 15/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//
//

import Foundation
import CoreData


extension CDCacheData {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCacheData> {
        fetchRequest(forKey: nil)
    }
    
    @nonobjc public class func fetchRequestMetadata() -> NSFetchRequest<CDCacheData> {
        let request = NSFetchRequest<CDCacheData>(entityName: "CDCacheData")
        request.propertiesToFetch = ["key", "expirationDate", "cacheTimeInterval"]
        return request
    }
    
    @nonobjc public class func fetchRequest(forKey key: String?) -> NSFetchRequest<CDCacheData> {
        let request = NSFetchRequest<CDCacheData>(entityName: "CDCacheData")
        if let key = key {
            request.predicate = .init(format: "key = %@", key)
        }
        return request
    }
    
    @nonobjc public class func fetchRequest(beforeDate date: Date) -> NSFetchRequest<CDCacheData> {
        let fetchRequest = NSFetchRequest<CDCacheData>(entityName: "CDCacheData")
        fetchRequest.predicate = NSPredicate(format: "expirationDate <= %@", date as NSDate)
        
        return fetchRequest
    }

    @NSManaged public var data: Data
    @NSManaged public var key: String
    @NSManaged public var expirationDate: Date
    @NSManaged public var cacheTimeInterval: Double

}
