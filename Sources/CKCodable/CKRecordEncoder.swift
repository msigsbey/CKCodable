//
//  CKRecordEncoder.swift
//  
//
//  Created by Michael Sigsbey on 11/11/22.
//

import Foundation
import CloudKit

/// Errors thrown by ``CKRecordEncoder``.
public enum CKRecordEncodingError: Error {

    /// Thrown when the encoded system fields fail to decode.
    case systemFieldsDecode(String)

    /// Thrown via `fatalError` when unsupported functionality is utilized.
    case unsupportedFunctionality

    /// Thrown when an usupported value is provided for a key.
    case unsupportedValueForKey(String)

    /// The localized description of the error.
    public var localizedDescription: String {
        switch self {
        case .unsupportedFunctionality:
            return "This functionality is currently unsupported"
        case .systemFieldsDecode(let message):
            return "Failed to process \(_CKSystemFieldsKeyName): \(message)"
        case .unsupportedValueForKey(let key):
            return """
                   The value of key \(key) is not supported. Only values that can be converted to
                   CKRecordValue are supported. Check the CloudKit documentation to see which types
                   can be used: https://developer.apple.com/documentation/cloudkit/ckrecord.
                   """
        }
    }
}

/// A specialized Encoder type for `CKRecord`.  In order to utilize this encoder, conform to ``CKCodable``.
public class CKRecordEncoder {

    /// Standard nitializer.
    public init() {}

    /// Encodes any `CKEncodable` into a valid `CKRecord`.
    /// - throws: This function throws an error if any values are invalid for the given encoder’s format.
    public func encode(
        _ value: CKEncodable
    ) throws -> CKRecord {
        let encoder = _CKRecordEncoder(provider: value.newRecordProvider)
        try value.encode(to: encoder)
        return encoder.record ?? value.newRecordProvider()
    }
}

final class _CKRecordEncoder {
    let provider: CKRecordProvider
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    fileprivate var container: CKRecordContainer?

    init(
        provider: @escaping CKRecordProvider
    ) {
        self.provider = provider
    }

    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }
}

extension _CKRecordEncoder: Encoder {
    var record: CKRecord? {
        container?.record
    }

    func container<Key>(
        keyedBy type: Key.Type
    ) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        assertCanCreateContainer()

        let container = KeyedContainer<Key>(
            provider: self.provider,
            codingPath: self.codingPath,
            userInfo: self.userInfo
        )

        self.container = container

        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError(CKRecordEncodingError.unsupportedFunctionality.localizedDescription)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError(CKRecordEncodingError.unsupportedFunctionality.localizedDescription)
    }
}

extension _CKRecordEncoder {
    final class KeyedContainer<Key> where Key: CodingKey {
        var provider: CKRecordProvider
        var internalRecord: CKRecord?
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        fileprivate var storage: [String: CKRecordValue] = [:]

        init(
            provider: @escaping CKRecordProvider,
            codingPath: [CodingKey],
            userInfo: [CodingUserInfoKey : Any]
        ) {
            self.provider = provider
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
}

extension _CKRecordEncoder.KeyedContainer: KeyedEncodingContainerProtocol {
    func encodeNil(forKey key: Key) throws {
        storage[key.stringValue] = nil
    }

    func encode<T>(
        _ value: T,
        forKey key: Key
    ) throws where T : Encodable {
        guard key.stringValue != _CKSystemFieldsKeyName else {
            guard let systemFields = value as? Data else {
                throw CKRecordEncodingError.systemFieldsDecode("\(_CKSystemFieldsKeyName) property must be of type Data")
            }

            try prepareInternalRecord(with: systemFields)

            return
        }

        storage[key.stringValue] = try produceCloudKitValue(for: value, withKey: key)
    }

    private func produceCloudKitValue<T>(
        for value: T,
        withKey key: Key
    ) throws -> CKRecordValue where T : Encodable {
        if let urlValue = value as? URL {
            return produceRecordValue(for: urlValue)
        } else if let recordValue = value as? CKRecordValue {
            return recordValue
        } else {
            throw CKRecordEncodingError.unsupportedValueForKey(key.stringValue)
        }
    }

    private func prepareInternalRecord(
        with systemFields: Data
    ) throws {
        let coder = try NSKeyedUnarchiver(forReadingFrom: systemFields)
        coder.requiresSecureCoding = true
        internalRecord = CKRecord(coder: coder)
        coder.finishDecoding()
    }

    private func produceRecordValue(
        for url: URL
    ) -> CKRecordValue {
        if url.isFileURL {
            return CKAsset(fileURL: url)
        } else {
            return url.absoluteString as CKRecordValue
        }
    }

    func nestedUnkeyedContainer(
        forKey key: Key
    ) -> UnkeyedEncodingContainer {
        fatalError(CKRecordEncodingError.unsupportedFunctionality.localizedDescription)
    }

    func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError(CKRecordEncodingError.unsupportedFunctionality.localizedDescription)
    }

    func superEncoder() -> Encoder {
        fatalError(CKRecordEncodingError.unsupportedFunctionality.localizedDescription)
    }

    func superEncoder(
        forKey key: Key
    ) -> Encoder {
        fatalError(CKRecordEncodingError.unsupportedFunctionality.localizedDescription)
    }
}

protocol CKRecordContainer {
    var record: CKRecord { get }
}

extension _CKRecordEncoder.KeyedContainer: CKRecordContainer {
    var record: CKRecord {
        let output: CKRecord

        if let internalRecord = self.internalRecord {
            output = internalRecord
        } else {
            output = provider()
        }

        for (key, value) in storage {
            output[key] = value
        }

        return output
    }
}
