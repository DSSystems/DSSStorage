//
//  DSSCacheManager.swift
//  DSSStorage
//
//  Created by David on 15/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

public protocol DSSHashable {
    var hash: Int { get }
}

open class DSSCacheManager {
    public static let shared = DSSCacheManager()
    
    private let coreDataManager: DSSCoreDataManager
    
    private var timer: Timer?
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    /// The time period (in seconds) when the manager will check the cached data
    public var checkingPeriod: TimeInterval = 60
    
    private init() {
        coreDataManager = DSSCoreDataManager(modelName: "DSSCacheCoreData", bundle: nil)
    }
    
    public func cache(data: Data?, forHashable hashable: DSSHashable, cachePeriod: TimeInterval) throws {
        try cache(data: data, forKey: "\(hashable.hash)", cachePeriod: cachePeriod)
    }
    
    public func cache(data: Data?, forKey key: String, cachePeriod: TimeInterval) throws {
        guard let data = data else { throw DSSCacheError.unwrap(varName: "data: Data?") }
        if let oldData: CDCacheData = try? getData(forKey: key) {
            let expirationDate = Date().addingTimeInterval(cachePeriod)
            oldData.expirationDate = expirationDate
            try? coreDataManager.context.save()
            #if DEBUG
            print("[\(String(reflecting: self))] Expiration date refreshed \(expirationDate) for object with key \(key)")
            #endif
            return
        }
        
        let cacheData = CDCacheData(context: coreDataManager.context)
        cacheData.key = key
        cacheData.data = data
        cacheData.cacheTimeInterval = cachePeriod
        cacheData.expirationDate = Date().addingTimeInterval(cachePeriod)
        try coreDataManager.context.save()
        #if DEBUG
        print("[\(String(reflecting: self))] Object cached for key: \(key), cache interval: \(Float(cachePeriod) / 60.0)min.\nDate: \(Date().addingTimeInterval(cachePeriod))")
        #endif
    }
    
    public func cache<T: Codable>(object: T, forHashable hashable: DSSHashable, cachePeriod: TimeInterval) throws {
        try cache(object: object, forKey: "\(hashable.hash)", cachePeriod: cachePeriod)
    }
    
    public func cache<T: Codable>(object: T, forKey key: String, cachePeriod: TimeInterval) throws {
        let objectData = try encoder.encode(object)
        try cache(data: objectData, forKey: key, cachePeriod: cachePeriod)
    }
        
    private func getData(forKey key: String) throws -> CDCacheData {
        let date = Date()
        let objects = try coreDataManager.context.fetch(CDCacheData.fetchRequest(forKey: key))
        guard let object = objects.first, object.expirationDate > date else { throw DSSCacheError.objectNotFound(key: key) }
        object.expirationDate = Date().addingTimeInterval(object.cacheTimeInterval)
        try? coreDataManager.context.save()
        #if DEBUG
        print("[\(String(reflecting: self))] Expiration date refreshed \(object.expirationDate) for object with key \(key)")
        #endif
        return object
    }
    
    public func getData(forHashable hashable: DSSHashable) throws -> Data {
        try getData(forKey: "\(hashable.hash)")
    }
    
    public func getData(forKey key: String) throws -> Data {
        let object: CDCacheData = try getData(forKey: key)
        return object.data
    }
    
    public func getObject<T: Codable>(forHashable hashable: DSSHashable) throws -> T {
        try getObject(forKey: "\(hashable.hash)")
    }
    
    public func getObject<T: Codable>(forKey key: String) throws -> T {
        let data: Data = try getData(forKey: key)
        return try decoder.decode(T.self, from: data)
    }
    
    public func beginMonitoringCachedData(checkingPeriod: TimeInterval = 60) {
        guard timer == nil else { return }
        self.checkingPeriod = checkingPeriod
        
        timer = Timer.scheduledTimer(withTimeInterval: checkingPeriod, repeats: true, block: { _ in
            self.handleCheckCachedData()
        })
        
        timer?.fire()
    }
    
    public func removeObject(forHashable hashable: DSSHashable) throws {
        try removeObject(forKey: "\(hashable.hash)")
    }
    
    public func removeObject(forKey key: String) throws {
        let objects = try coreDataManager.context.fetch(CDCacheData.fetchRequest(forKey: key))
        objects.forEach { coreDataManager.context.delete($0) }
        try coreDataManager.context.save()
    }
    
    public func stopMonitoringCachedData() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc public func handleCheckCachedData() {
        #if DEBUG
        print("[\(String(reflecting: self)) \(Date())] Checking cached data")
        #endif
        
        guard let objects: [CDCacheData] = try? coreDataManager.context.fetch(CDCacheData.fetchRequest(beforeDate: Date())) else {
            #if DEBUG
            print("[\(String(reflecting: self)) \(Date())] Nothing to clean.")
            #endif
            return
        }
        
        objects.forEach({
            #if DEBUG
            print("[\(String(reflecting: self))] Deleting object for key: \($0.key), expirationDate: \($0.expirationDate)")
            #endif
            coreDataManager.context.delete($0)
        })
        
        try? coreDataManager.context.save()
        
//        do {
//            let cachedData: [CDCacheData] = try coreDataManager.context.fetch(CDCacheData.fetchRequestMetadata())
//            #if DEBUG
//            cachedData.enumerated().forEach { offset, item in
//                print("[\(offset)] \(item.key): \(item.expirationDate) (\(item.cacheTimeInterval))")
//            }
//            print("[\(String(reflecting: self))] Total cached data: \(cachedData.count)")
//            #endif
//        } catch {
//            #if DEBUG
//            print("[\(String(reflecting: self))] Failed to check all cached data")
//            #endif
//        }
    }
}
