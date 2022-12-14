//
//  CKRecordDecoder.swift
//  
//
//  Created by Michael Sigsbey on 11/11/22.
//

import Foundation
import CloudKit

/// Errors thrown by ``CKRecordDecoder``.
public enum CKRecordDecodingError: Error {
    /// Thrown via `fatalError` when unsupported functionality is utilized.
    case unsupportedFunctionality

    /// The localized description of the error.
    public var localizedDescription: String {
        switch self {
        case .unsupportedFunctionality:
            return "This functionality is currently unsupported."
        }
    }
}

/// A specialized Decoder type for `CKRecord`.  In order to utilize this decoder, conform to ``CKCodable``.
final public class CKRecordDecoder {

    /// Standard initializer.
    public init() {}

    /// Decodes `CKRecord` into the specified type.
    /// - parameters:
    ///   - type: The `CKDecodable` type that the input record should be decoded into.
    ///   - record: The `CKRecord` to decode.
    /// - throws: This function throws an error if any values are invalid for the given encoder’s format.

    public func decode<T>(
        _ type: T.Type, from record: CKRecord
    ) throws -> T where T : CKDecodable {
        let decoder = _CKRecordDecoder(record: record)
        return try T(from: decoder)
    }

    /// Decodes `CKRecord` into the inferred type based on context.  Must conform to CKDecodable.
    /// - parameters:
    ///   - record: The `CKRecord` to decode.
    /// - throws: This function throws an error if any values are invalid for the given encoder’s format.
    public func decode<T>(
        from record: CKRecord
    ) throws -> T where T : CKDecodable {
        let decoder = _CKRecordDecoder(record: record)
        return try T(from: decoder)
    }
}

final class _CKRecordDecoder {
    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey : Any] = [:]

    var container: CKRecordDecodingContainer?
    fileprivate var record: CKRecord

    init(
        record: CKRecord
    ) {
        self.record = record
    }
}

extension _CKRecordDecoder: Decoder {
    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }

    func container<Key>(
        keyedBy type: Key.Type
    ) -> KeyedDecodingContainer<Key> where Key : CodingKey {
        assertCanCreateContainer()

        let container = KeyedContainer<Key>(
            record: self.record,
            codingPath: self.codingPath,
            userInfo: self.userInfo
        )

        self.container = container

        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedDecodingContainer {
        fatalError(CKRecordDecodingError.unsupportedFunctionality.localizedDescription)
    }

    func singleValueContainer() -> SingleValueDecodingContainer {
        fatalError(CKRecordDecodingError.unsupportedFunctionality.localizedDescription)
    }
}

protocol CKRecordDecodingContainer: AnyObject {
    var codingPath: [CodingKey] { get set }

    var userInfo: [CodingUserInfoKey : Any] { get }

    var record: CKRecord { get set }
}

extension _CKRecordDecoder {
    final class KeyedContainer<Key> where Key: CodingKey {
        var record: CKRecord
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        private lazy var systemFieldsData: Data = {
            return decodeSystemFields()
        }()

        init(
            record: CKRecord,
            codingPath: [CodingKey],
            userInfo: [CodingUserInfoKey : Any]
        ) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.record = record
        }

        func checkCanDecodeValue(
            forKey key: Key
        ) throws {
            guard self.contains(key) else {
                let context = DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "key not found: \(key)"
                )
                throw DecodingError.keyNotFound(key, context)
            }
        }

        func nestedCodingPath(
            forKey key: CodingKey
        ) -> [CodingKey] {
            return self.codingPath + [key]
        }
    }
}

extension _CKRecordDecoder.KeyedContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        return self.record.allKeys().compactMap { Key(stringValue: $0) }
    }

    func contains(
        _ key: Key
    ) -> Bool {
        guard key.stringValue != _CKSystemFieldsKeyName else { return true }

        return allKeys.contains(where: { $0.stringValue == key.stringValue })
    }

    func decodeNil(
        forKey key: Key
    ) throws -> Bool {
        try checkCanDecodeValue(forKey: key)

        if key.stringValue == _CKSystemFieldsKeyName {
            return systemFieldsData.count == 0
        } else {
            return record[key.stringValue] == nil
        }
    }

    func decodeIfPresent<T>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T? where T : Decodable {
        return try? decode(type, forKey: key)
    }

    func decode<T>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T where T : Decodable {
        try checkCanDecodeValue(forKey: key)

        #if DEBUG
        print("decode key: \(key.stringValue)")
        #endif

        // Decode the systemFieldsData
        if key.stringValue == _CKSystemFieldsKeyName {
            return systemFieldsData as! T
        }

        // Bools are encoded as Int64 in CloudKit
        if type == Bool.self {
            return try decodeBool(forKey: key) as! T
        }

        // URLs are encoded as String (remote) or CKAsset (file URL) in CloudKit
        if type == URL.self {
            return try decodeURL(forKey: key) as! T
        }

        guard let value = record[key.stringValue] as? T else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "CKRecordValue couldn't be converted to \(String(describing: type))'"
            )
            throw DecodingError.typeMismatch(type, context)
        }

        return value
    }

    private func decodeURL(
        forKey key: Key
    ) throws -> URL {
        if let asset = record[key.stringValue] as? CKAsset {
            return try decodeURL(from: asset)
        }

        guard let string = record[key.stringValue] as? String else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "URL should have been encoded as String in CKRecord"
            )
            throw DecodingError.typeMismatch(URL.self, context)
        }

        return try decodeURL(from: string)
    }

    private func decodeURL(
        from string: String
    ) throws -> URL {
        guard let url = URL(string: string) else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "The string \(string) is not a valid URL"
            )
            throw DecodingError.typeMismatch(URL.self, context)
        }

        return url
    }

    private func decodeURL(
        from asset: CKAsset
    ) throws -> URL {
        guard let url = asset.fileURL else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "URL value not found"
            )
            throw DecodingError.valueNotFound(URL.self, context)
        }

        return url
    }

    private func decodeBool(
        forKey key: Key
    ) throws -> Bool {
        guard let intValue = record[key.stringValue] as? Int64 else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Bool should have been encoded as Int64 in CKRecord"
            )
            throw DecodingError.typeMismatch(Bool.self, context)
        }

        return intValue == 1
    }

    private func decodeSystemFields() -> Data {
        let coder = NSKeyedArchiver.init(requiringSecureCoding: true)
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()

        return coder.encodedData
    }

    func nestedUnkeyedContainer(
        forKey key: Key
    ) throws -> UnkeyedDecodingContainer {
        fatalError(CKRecordDecodingError.unsupportedFunctionality.localizedDescription)
    }

    func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError(CKRecordDecodingError.unsupportedFunctionality.localizedDescription)
    }

    func superDecoder() throws -> Decoder {
        return _CKRecordDecoder(record: record)
    }

    func superDecoder(
        forKey key: Key
    ) throws -> Decoder {
        let decoder = _CKRecordDecoder(record: self.record)
        decoder.codingPath = [key]

        return decoder
    }
}

extension _CKRecordDecoder.KeyedContainer: CKRecordDecodingContainer {}
