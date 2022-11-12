//
//  CKCodable.swift
//  
//
//  Created by Michael Sigsbey on 11/11/22.
//

import Foundation
import CloudKit

/// The internal system fields key
internal let _CKSystemFieldsKeyName = "systemFields"

/// A tyepalias for generating a new record for a ``CKCodable``.
public typealias CKRecordProvider = () -> CKRecord

/// The main protocol conformance required by the ``CKCodable`` type.
///
/// This `systemFields` is a `Data` container for the [encodedSystemFields](https://developer.apple.com/documentation/cloudkit/ckrecord/1462200-encodesystemfields) to store the underlying ``CKRecord`` while cached.  This is used for metadata so that it can be inflated later with the relevant information required to diff records.
///
///  and a ``CKRecordProvider`` for creating new records of a given type allowing each type to specify a series of zones, 
public protocol CKRecordRepresentable {
    var systemFields: Data? { get }
    var newRecordProvider: CKRecordProvider { get }
}

/// A new record provider that creates a CKRecord with defautl values
extension CKRecordRepresentable {
    var newRecordProvider: CKRecordProvider {
        {
            CKRecord(
                recordType: String(describing: Self.self),
                recordID: CKRecord.ID(
                    recordName: UUID().uuidString,
                    zoneID: .default
                )
            )
        }
    }
}

/// Underlying type for CKRecord encoding
public protocol CKEncodable: CKRecordRepresentable & Encodable {}

/// Underlying type for CKRecord decoding
public protocol CKDecodable: CKRecordRepresentable & Decodable {}

/// Conform to this type to enable CKRecord encoding and decoding
public protocol CKCodable: CKEncodable & CKDecodable {}
