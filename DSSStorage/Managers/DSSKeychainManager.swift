//
//  DSSKeychainManager.swift
//  DSSStorage
//
//  Created by David on 13/12/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Security

fileprivate extension Dictionary where Key == CFString, Value == Any  {
    var cfDictionary: CFDictionary {
        return self as CFDictionary
    }
}

public struct DSSKeychainKey {
    public let label: String
    public let identifier: Data
    public let value: Data
    
    public init(value: String, label: String) throws {
        guard let valueData = value.data(using: .utf8) else { throw DSSKeychainError.unwrap(varName: "\(Self.self).value") }
        guard let identifier = label.data(using: .utf8) else { throw DSSKeychainError.unwrap(varName: "\(Self.self).label") }
        self.value = valueData
        self.identifier = identifier
        self.label = label
    }
    
    public init<T: Codable>(object: T, label: String) throws {
        guard let identifier = label.data(using: .utf8) else { throw DSSKeychainError.unwrap(varName: "\(Self.self).label") }
        value = try JSONEncoder().encode(object)
        self.label = label
        self.identifier = identifier
    }
    
    public init<T: Codable, K: RawRepresentable>(object: T, identifier id: K) throws where K.RawValue == String {
        try self.init(object: object, label: id.rawValue)
    }
    
    public func object<T: Codable>() throws -> T {
        return try JSONDecoder().decode(T.self, from: value)
    }
    
    public init?(_ item: [CFString: Any]) {
        guard let label = item[kSecAttrLabel] as? String, let valueData = item[kSecValueData] as? Data else {
            return nil
        }
        guard let identifier = label.data(using: .utf8) else { return nil }
        self.value = valueData
        self.identifier = identifier
        self.label = label
    }
}

public protocol DSSKeychainLabelable {
}

public extension DSSKeychainLabelable {
    static func keychainLabel(_ complementId: String? = nil) -> String {
        guard let complementId = complementId else {
            return "\(DSSKeychainManager.self).\(Self.self)"
        }
        
        return "\(DSSKeychainManager.self).\(Self.self).\(complementId)"
    }
}

public struct DSSKeychainCredentials {
    
    // MARK: - Types
    
    public enum AccountType { case generic, internet }
    
    // MARK: - Properties
    
    public let username: String
    public let password: String
    
    public let server: String?
    public let type: AccountType
    
    public init(username: String, password: String, server: String?, type: AccountType) {
        self.username = username
        self.password = password
        
        self.server = server
        self.type = type
    }
    
    public init?(_ cfDictionary: [CFString: Any], type: AccountType) {
        guard let passwordData = cfDictionary[kSecValueData] as? Data,
            let password = String(data: passwordData, encoding: .utf8),
            let account = cfDictionary[kSecAttrAccount] as? String
            else {
                return nil
        }
        
        self.username = account
        self.password = password
        self.server = cfDictionary[kSecAttrServer] as? String
        self.type = type
    }
}

final public class DSSKeychainManager {
    // MARK: - Types
    
    public enum ClassType {
        case key
        case account(type: DSSKeychainCredentials.AccountType)
    }
    
    // MARK: - Properties
    
    public static let shared = DSSKeychainManager()
    
    public func update(credentials: DSSKeychainCredentials) throws {
        guard let passwordData = credentials.password.data(using: .utf8) else {
            throw DSSKeychainError.unexpectedValueData
        }
        
        let `class`: CFString = credentials.type == .internet ? kSecClassInternetPassword : kSecClassGenericPassword
        
        var query: [CFString: Any] = [kSecClass: `class`,
                                      kSecAttrAccount: credentials.username]
        
        if let server = credentials.server, credentials.type == .internet { query[kSecAttrServer] = server }
        
        let attributes: [CFString: Any] = [kSecValueData: passwordData]
        
        let status = SecItemUpdate(query.cfDictionary, attributes.cfDictionary)
        
        if status == errSecItemNotFound {
            try store(credentials: credentials)
        } else {
            guard status == errSecSuccess else { throw DSSKeychainError.keychain(status: status) }
        }
    }
    
    public func update(key: DSSKeychainKey) throws {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                      kSecAttrLabel: key.label,
                                      kSecAttrAccount: key.identifier,
                                      kSecAttrGeneric: key.identifier]        
        let attributes: [CFString: Any] = [kSecValueData: key.value]
        
        let status = SecItemUpdate(query.cfDictionary, attributes.cfDictionary)
        
        if status == errSecItemNotFound {
            try store(key: key)
        } else {
            guard status == errSecSuccess else { throw DSSKeychainError.keychain(status: status) }
        }
    }
    
    private func store(key: DSSKeychainKey) throws {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                      kSecAttrLabel: key.label,
                                      kSecAttrGeneric: key.identifier,
                                      kSecAttrAccount: key.identifier,
                                      kSecValueData: key.value]
        try store(query: query)
    }
    
    private func store(credentials: DSSKeychainCredentials) throws {
        let account = credentials.username
        guard let passwordData = credentials.password.data(using: .utf8) else { throw DSSKeychainError.unexpectedValueData }
        
        let `class`: CFString = credentials.type == .internet ? kSecClassInternetPassword : kSecClassGenericPassword
        
        var query: [CFString: Any] = [kSecClass: `class`, kSecAttrAccount: account, kSecValueData: passwordData]
        
        if let server = credentials.server, credentials.type == .internet { query[kSecAttrServer] = server }
        
        let status = SecItemAdd(query.cfDictionary, nil)
        
        guard status == errSecSuccess else { throw DSSKeychainError.keychain(status: status) }
    }
    
    public func remove(username: String?,
                       type: DSSKeychainCredentials.AccountType,
                       server: String?) throws {
        let `class`: CFString = type == .internet ? kSecClassInternetPassword : kSecClassGenericPassword
        
        var query: [CFString: Any] = [kSecClass: `class`]
        
        if let username = username { query[kSecAttrAccount] = username }
        if let server = server, type == .internet { query[kSecAttrServer] = server }
        
        try remove(query: query)
    }
    
    public func remove(keyForLabel label: String) throws {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrLabel: label]
        try remove(query: query)
    }
    
    public func remove<K: RawRepresentable>(keyForIdentifier identifier: K) throws where K.RawValue == String {
        try remove(keyForLabel: identifier.rawValue)
    }
    
    public func fetch(keyForLabel label: String) throws -> DSSKeychainKey {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                      kSecAttrLabel: label,
                                      kSecReturnAttributes: true,
                                      kSecReturnData: true]
        
        let existingItem = try fetch(query: query)
        guard let key = DSSKeychainKey(existingItem) else { throw DSSKeychainError.unwrap(varName: "DSSKeychainKey") }
        return key
    }
    
    public func fetch<T: RawRepresentable>(identifier: T) throws -> DSSKeychainKey where T.RawValue == String {
        try fetch(keyForLabel: identifier.rawValue)
    }
    
    public func fetchCredentials(username: String?,
                                 type: DSSKeychainCredentials.AccountType,
                                 server: String) throws -> DSSKeychainCredentials {
        let `class`: CFString = type == .internet ? kSecClassInternetPassword : kSecClassGenericPassword
        
        var query: [CFString: Any] = [kSecClass: `class`,
                                      kSecMatchLimit: kSecMatchLimitOne,
                                      kSecReturnAttributes: true,
                                      kSecReturnData: true]
        
        if type == .internet { query[kSecAttrServer] = server }
        
        if let username = username { query[kSecAttrAccount] = username }
        
        let existingItem = try fetch(query: query)
        
        guard let credentials = DSSKeychainCredentials(existingItem, type: type) else {
            throw DSSKeychainError.unwrap(varName: "DSSKeychainCredentials")
        }
        
        return credentials
    }
    
    private func fetch(query: [CFString: Any]) throws -> [CFString: Any] {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query.cfDictionary, &item)
        
        guard status != errSecItemNotFound else { throw DSSKeychainError.noData }
        guard status == errSecSuccess else { throw DSSKeychainError.keychain(status: status) }
        
        guard let existingItem = item as? [CFString : Any] else { throw DSSKeychainError.unexpectedValueData }
        
        return existingItem
    }
    
    private func store(query: [CFString: Any]) throws {
        let status = SecItemAdd(query.cfDictionary, nil)

        guard status == errSecSuccess else { throw DSSKeychainError.keychain(status: status) }
    }
    
    private func remove(query: [CFString: Any]) throws {
        let status = SecItemDelete(query.cfDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw DSSKeychainError.keychain(status: status) }
    }
}
