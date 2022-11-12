//
//  TestUtils.swift
//  
//
//  Created by Michael Sigsbey on 11/11/22.
//

import CloudKit
import Foundation
import XCTest

@testable import CKCodable

extension CKRecord {
    /// Creates a temporary record to simulate what would happen when encoding a `CKRecord`
    /// from a value that was previosly encoded to a `CKRecord` and had its system fields set
    static var systemFieldsDataForTesting: Data {
        let zoneID = CKRecordZone.ID(zoneName: "ZoneABCD", ownerName: "OwnerABCD")
        let recordID = CKRecord.ID(recordName: "RecordABCD", zoneID: zoneID)
        let testRecord = CKRecord(recordType: "TypeABCD", recordID: recordID)
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        testRecord.encodeSystemFields(with: coder)
        coder.finishEncoding()

        return coder.encodedData
    }

    /// Loads the test `CKRecord` which has been encoded and archived to file
    static var testRecord: CKRecord {
        get throws {
            guard let url = Bundle.module.url(forResource: "Tester", withExtension: "ckrecord") else {
                fatalError("Required test asset Tester.ckrecord not found")
            }

            let data = try Data(contentsOf: url)
            let record = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.self, from: data)

            return try XCTUnwrap(record)
        }
    }

    /// Validates that all fields in self match the expectations of encoding the test `CKCodable` struct to a `CKRecord`
    ///
    /// - Parameters:
    ///   - type: A `CKRecord.RecordType` to match against the `CKRecord`.
    ///   - name: A `String` name to match against the `CKRecord.ID` recordName.
    ///   - zone: A `CKRecordZone.ID` to match against the `CKRecord.ID` zoneID.
    func validateFields(
        type: CKRecord.RecordType? = nil,
        name: String? = nil,
        zone: CKRecordZone.ID? = nil
    ) throws {
        if let type = type {
            XCTAssertEqual(self.recordType, type)
        }
        if let name = name {
            XCTAssertEqual(self.recordID.recordName, name)
        }
        if let zone = zone {
            XCTAssertEqual(self.recordID.zoneID, zone)
        }
        XCTAssertEqual(self["name"] as? String, "Tester Testerson")
        XCTAssertEqual(self["createdAt"] as? Date, Date(timeIntervalSince1970: 0))

        XCTAssertNil(self[_CKSystemFieldsKeyName], "\(_CKSystemFieldsKeyName) should NOT be encoded to the record directly")
    }

    /// Switch to macOS target to generate the Tester.ckrecord file.
    #if os(macOS)
    static func generateTestRecord() throws -> Bool {
        let recordData = try CKRecordEncoder().encode(Test.Tester)
        let data = try NSKeyedArchiver.archivedData(withRootObject: recordData, requiringSecureCoding: false)

        return FileManager.default.createFile(
            atPath: testFilePath,
            contents: data,
            attributes: nil
        )
    }

    static var testFilePath: String {
        return "/tmp/Tester.ckrecord"
    }
    #endif
}

#if os(macOS)
final class GenerateTestRecordTests: XCTestCase {
    func testGenerateTestRecord() throws {
        XCTAssertTrue(try CKRecord.generateTestRecord())
        FileManager.default.fileExists(atPath: CKRecord.testFilePath)
        print("Generated record at: \(CKRecord.testFilePath)")
    }
}
#endif
