//
//  CKRecordDecoderTests.swift
//  
//
//  Created by Michael Sigsbey on 11/12/22.
//

import CloudKit
import XCTest

@testable import CKCodable

final class CKRecordDecoderTests: XCTestCase {
    private func _validateDecodedPerson(_ tester: Test) {
        XCTAssertEqual(tester, Test.Tester)
        XCTAssertNotNil(tester.underlyingRecord?.recordID.recordName, "\(_CKSystemFieldsKeyName) should bet set for a value conforming to CloudKitRecordRepresentable decoded from an existing CKRecord")
    }

    private func _validateDecodedPerson(_ tester: TestCustomZone) {
        XCTAssertEqual(tester, TestCustomZone.Tester)
        XCTAssertNotNil(tester.underlyingRecord?.recordID.recordName, "\(_CKSystemFieldsKeyName) should bet set for a value conforming to CloudKitRecordRepresentable decoded from an existing CKRecord")
    }

    private func _validateDecodedPerson(_ tester: TestCustomIdentifierAndZone) {
        XCTAssertEqual(tester, TestCustomIdentifierAndZone.Tester)
        XCTAssertNotNil(tester.underlyingRecord?.recordID.recordName, "\(_CKSystemFieldsKeyName) should bet set for a value conforming to CloudKitRecordRepresentable decoded from an existing CKRecord")
    }

    func testComplexPersonStructDecoding() throws {
        let person = try CKRecordDecoder().decode(Test.self, from: CKRecord.testRecord)

        _validateDecodedPerson(person)
    }

    func testRoundTrip() throws {
        let encodedPerson = try CKRecordEncoder().encode(Test.Tester)
        let samePersonDecoded = try CKRecordDecoder().decode(Test.self, from: encodedPerson)

        _validateDecodedPerson(samePersonDecoded)
    }

    func testRoundTripWithCustomZoneID() throws {
        let encodedPerson = try CKRecordEncoder().encode(Test.Tester)
        let samePersonDecoded = try CKRecordDecoder().decode(Test.self, from: encodedPerson)
        let samePersonReencoded = try CKRecordEncoder().encode(samePersonDecoded)

        _validateDecodedPerson(samePersonDecoded)
        XCTAssert(encodedPerson.recordID.zoneID == samePersonReencoded.recordID.zoneID)
        XCTAssert(encodedPerson.recordID.recordName == samePersonReencoded.recordID.recordName)
    }

    func testCustomRecordIdentifierRoundTrip() throws {
        let zoneID = CKRecordZone.ID(zoneName: "Zone12345", ownerName: CKCurrentUserDefaultName)
        let record = try CKRecordEncoder().encode(TestCustomIdentifierAndZone.Tester)

        XCTAssert(record.recordID.zoneID == zoneID)
        XCTAssert(record.recordID.recordName == "TEST-ID")

        let samePersonDecoded = try CKRecordDecoder().decode(TestCustomIdentifierAndZone.self, from: record)

        _validateDecodedPerson(samePersonDecoded)
    }
}
