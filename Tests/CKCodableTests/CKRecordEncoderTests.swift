//
//  CKRecrdEndcoderTests.swift
//  
//
//  Created by Michael Sigsbey on 11/12/22.
//

import CloudKit
import XCTest

@testable import CKCodable

final class CKRecrdEndcoderTests: XCTestCase {
    func testComplexPersonStructEncoding() throws {
        let record = try CKRecordEncoder().encode(Test.Tester)
        try _validateFields(
            in: record,
            type: String(describing:Test.self),
            zone: .default
        )
    }

    func testCustomZoneIDEncoding() throws {
        let zoneID = CKRecordZone.ID(zoneName: "ABCDE", ownerName: CKCurrentUserDefaultName)
        let record = try CKRecordEncoder().encode(TestCustomZone.Tester)
        try _validateFields(
            in: record,
            type: String(describing:TestCustomZone.self),
            zone: zoneID
        )
    }

    func testSystemFieldsEncoding() throws {
        var previouslySavedTester = Test.Tester

        previouslySavedTester.systemFields = CKRecord.systemFieldsDataForTesting

        let record = try CKRecordEncoder().encode(previouslySavedTester)

        try _validateFields(
            in: record,
            type: "TypeABCD",
            name: "RecordABCD",
            zone: CKRecordZone.ID(zoneName: "ZoneABCD", ownerName: "OwnerABCD")
        )
    }

    func testCustomRecordIdentifierEncoding() throws {
        let record = try CKRecordEncoder().encode(TestCustomIdentifierAndZone.Tester)

        try _validateFields(
            in: record,
            name: "TEST-ID",
            zone: CKRecordZone.ID(zoneName: "Zone12345", ownerName: CKCurrentUserDefaultName)
        )
    }
}
