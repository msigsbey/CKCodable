//
//  File.swift
//  
//
//  Created by Michael Sigsbey on 11/6/22.
//

import CloudKit

@testable import CKCodable

struct Test: CKCodable, Equatable {
    var systemFields: Data?
    let name: String
    let createdAt: Date

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

    /// Custom override for equality to exclude the system data.  This allows quick comparison of data prior to and after encoding.
    static func ==(lhs: Test, rhs: Test) -> Bool {
        return lhs.name == rhs.name &&
        lhs.createdAt == rhs.createdAt
    }
}

extension Test {
    /// Sample person for tests
    static let Tester = Test(
        systemFields: nil,
        name: "Tester Testerson",
        createdAt: Date.init(timeIntervalSince1970: 0)
    )
}

extension CKCodable {
    /// Allows looking at the underlying record.
    var underlyingRecord: CKRecord? {
        guard let systemFields = systemFields,
              let coder = try? NSKeyedUnarchiver(forReadingFrom: systemFields)
        else {
            return nil
        }
        coder.requiresSecureCoding = true
        let record = CKRecord(coder: coder)
        coder.finishDecoding()
        return record
    }
}
