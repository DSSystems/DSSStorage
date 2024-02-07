//
//  DSSFileManager.swift
//  DSSStorage
//
//  Created by David on 13/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

public extension Array where Element == DSSFileManager.Item {
    func printed() {
        self.forEach {
            let typeDescription = $0.type == .directory ? "Directory" : "File"
            print("\(typeDescription): \($0.name)")
        }
    }
}

public extension FileManager {
    func directoryExists(at path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    func directoryExists(at url: URL) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

final public class DSSFileManager {
    public typealias DirectoryPath = String
    
    public struct Item {
        public enum ElementType { case directory, file }
        public let type: ElementType
        public let name: String
    }
    
    public static let standard = DSSFileManager()
    public let manager = FileManager.default
    public let documentDirectory: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: false)
        } catch { fatalError("This should not happen: \(error.localizedDescription)") }
    }()
    
    private var currentUrlDirectory: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: false)
        } catch { fatalError("This should not happen: \(error.localizedDescription)") }
    }()
    
    public var currentDirectory: String {
        return currentUrlDirectory.path
    }
    
    private init() { }
    
    public func mv(from currentPath: String, to newPath: String) throws {
        let currentUrl = URL(fileURLWithPath: currentPath)
        let newUrl = URL(fileURLWithPath: newPath)
        
        try manager.moveItem(at: currentUrl, to: newUrl)
    }
    
    public func moveToDocumentDirectory(from currentPath: String, name: String) throws {
        let documentDirectory = try manager.url(for: .documentDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil, create: false)
        
        try mv(from: currentPath, to: documentDirectory.appendingPathComponent(name).path)
    }
    
    public func ls(at url: URL) -> [Item] {
        do {
            let items = try manager.contentsOfDirectory(at: url,
                                                        includingPropertiesForKeys: [URLResourceKey.isDirectoryKey],
                                                        options: .skipsHiddenFiles)
            return items.map({
                return Item(type: $0.hasDirectoryPath ? .directory : .file, name: $0.lastPathComponent)
            })
        } catch {
            print("Failed to list contents of '\(url.path)'. \(error.localizedDescription)")
            return []
        }
    }
    
    public func ls(at path: DirectoryPath = "./") -> [Item] {
        let url: URL = fullUrlPath(for: path)
        return ls(at: url)
    }
    
    public func cd(at path: String = "./") {
        currentUrlDirectory = fullUrlPath(for: path)
    }
    
    public func rename(path: DirectoryPath? = nil, currectName: String, newName: String) throws {
        let url: URL = URL(fileURLWithPath: path) ?? documentDirectory
        
        try mv(from: url.appendingPathComponent(currectName).path, to: url.appendingPathComponent(newName).path)
    }
        
    public func write(data: Data?, at url: URL, name: String) throws {
        guard let data = data else { return }
        try data.write(to: url.appendingPathComponent(name), options: .atomic)
    }
    
    public func write(data: Data?, at path: DirectoryPath = "./", name: String) throws {
        let url: URL = fullUrlPath(for: path)
        try write(data: data, at: url, name: name)
    }
    
    public func readData(at url: URL, name: String) throws -> Data {
        let path = url.appendingPathComponent(name).path
        guard let fileData = manager.contents(atPath: path) else {
            throw DSSFileError.notFound(path: url.path)
        }
        return fileData
    }
    
    public func readData(at path: DirectoryPath = "./", name: String) throws -> Data {
        let url: URL = fullUrlPath(for: path)
        return try readData(at: url, name: name)
    }
    
    public func mkdir(at path: DirectoryPath? = nil, name: String) throws {
        let url: URL = URL(fileURLWithPath: path) ?? documentDirectory
        
        guard !manager.directoryExists(at: url.appendingPathComponent(name).path) else { return }
        
        try manager.createDirectory(at: url.appendingPathComponent(name),
                                    withIntermediateDirectories: true,
                                    attributes: nil)
    }
    
    public func rm(url: URL) throws { try manager.removeItem(at: url) }
    
    public func rm(at path: DirectoryPath, filename: String? = nil) throws {
        let url = fullUrlPath(for: path)
        guard let filename = filename else {
            return try rm(url: url)
        }
        return try rm(url: url.appendingPathComponent(filename))
    }
    
    private func fullUrlPath(for relativePath: DirectoryPath) -> URL {
        let components: [String] = relativePath.split(separator: "/").map({ String($0) })
        var url = currentUrlDirectory
        components.forEach {
            switch $0 {
            case ".": break
            case "..": url = url.deletingLastPathComponent()
            default: url = url.appendingPathComponent($0)
            }
        }
        return url
    }
}
