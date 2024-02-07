//
//  DSSSecurity.swift
//  DSSStorage
//
//  Created by David on 06/05/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation

open class DSSSecurity {
    public typealias Base64String = String
    public class func encrypt(message: String, publicKey: Base64String) -> String? {
        return nil
//        guard let publicKey = Data(base64Encoded: publicKey) else { return nil }
//        let options: [CFString: Any] = [
//            kSecAttrType: kSecAttrKeyTypeRSA,
//            kSecAttrKeyClass: kSecAttrKeyClassPublic,
//            kSecAttrKeySizeInBits: NSNumber(value: 2048),
//            kSecReturnPersistentRef: true
//        ]
//
//        var error: CFError
//
//        guard let secKey = SecKeyCreateWithData(publicKey as CFData, options as CFDictionary, &error) else {
//            print(error?.pointee)
//            return nil
//        }
//
//        let blockSize = SecKeyGetBlockSize(secKey)
//        var messageEncrypted: [UInt8] = .init(repeating: 0, count: blockSize)
//        var messageEncryptedSize = blockSize
//
//        let status: OSStatus = SecKeyEncrypt(secKey, .PKCS1, message, message.count, &messageEncrypted, &messageEncryptedSize)
//
//        guard status != noErr else { return nil }
//
//        return Data(bytes: messageEncrypted, count: messageEncryptedSize).base64EncodedString()
    }
}
