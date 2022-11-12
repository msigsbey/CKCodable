//
//  Test.swift
//  
//
//  Created by Michael Sigsbey on 11/6/22.
//

import CloudKit

@testable import CKCodable

/// A test object with basic types and default record generation.
struct Test: CKCodable, Equatable {
    var systemFields: Data?
    /// A `Bool` flag.
    let flag: Bool
    /// A `String` name.
    let name: String
    /// A creation `Date`.
    let createdAt: Date
    /// A `URL` link.
    let link: URL
    /// A file `URL`.
    let file: URL

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
        flag: true,
        name: "Tester Testerson",
        createdAt: Date.init(timeIntervalSince1970: 0),
        link: URL(string: "http://www.apple.com")!,
        file: Bundle.module.url(forResource: "apple-logo", withExtension: "png")!
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
