//
//  TestCustomIdentifierAndZone.swift
//  
//
//  Created by Michael Sigsbey on 11/12/22.
//

import CloudKit

@testable import CKCodable

/// A test object with basic types and a custom identifier and zone for record generation.
struct TestCustomIdentifierAndZone: CKCodable, Equatable {
    var systemFields: Data?
    /// A `String` name.
    let name: String
    /// A `Date` for creation time.
    let createdAt: Date

    var newRecordProvider: CKRecordProvider {
        {
            CKRecord(
                recordType: String(describing: Self.self),
                recordID: CKRecord.ID(
                    recordName: "TEST-ID",
                    zoneID: CKRecordZone.ID(
                        zoneName: "Zone12345",
                        ownerName: CKCurrentUserDefaultName
                    )
                )
            )
        }
    }

    /// Custom override for equality to exclude the system data.  This allows quick comparison of data prior to and after encoding.
    static func ==(lhs: TestCustomIdentifierAndZone, rhs: TestCustomIdentifierAndZone) -> Bool {
        return lhs.name == rhs.name &&
        lhs.createdAt == rhs.createdAt
    }
}

extension TestCustomIdentifierAndZone {
    static let Tester = TestCustomIdentifierAndZone(
        systemFields: nil,
        name: "Tester Testerson",
        createdAt: Date.init(timeIntervalSince1970: 0)
    )
}
