# CKCodable
A library for encoding and decoding CKRecords

![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/msigsbey/CKCodable)
[![Swift Package Manager](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
![Swift5](https://img.shields.io/badge/Swift-5-orange.svg)
![Platform](https://img.shields.io/badge/platform-iOS|macOS|tvOS|watchOS-blue.svg?style=flat)
![GitHub repo size](https://img.shields.io/github/repo-size/msigsbey/CKCodable)

CKCodable is a type built to streamline the data pipeline between a [Codable](https://developer.apple.com/documentation/swift/codable/) object and a CloudKit [CKRecord](https://developer.apple.com/documentation/cloudkit/ckrecord).

## Integration

CKCodable is available via [Swift Package Manager](https://swift.org/package-manager/)

## Usage

Conform to `CKCodable` to enable encoding and decoding with the `CKRecordEncoder` and `CKRecordDecoder` respectively.  It can be integrated within your system like this: 

### Step 1 - Import CKCodable
```swift
import CKCodable

```
### Step 2 - Implement CKCodable
```swift
public struct SomeType: CKCodable {
    var systemFields: Data?
    
    /*
    Note: Optionl override for default record provider.
    var newRecordProvider: CKRecordProvider {
        {
            CKRecord(
                recordType: String(describing: Self.self), // RecordType using self
                recordID: CKRecord.ID(
                    recordName: UUID().uuidString, // RecordName as random UUID
                    zoneID: .default // Default CKRecordZone
                )
            )
        }
    }
    */
}
```

### Step 3 - Add your own values from the [Supported Data Types](https://developer.apple.com/documentation/cloudkit/ckrecord)
```swift
public struct SomeType: CKCodable {
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
}
```

### Step 4 - Encode and Decode your types
```swift
// Encode to CKRecord
let obj: SomeType = // input Sometype
let record: CKRecord = try CKRecordEncoder().encode(obj)

// Decode to SomeType
let record: CKRecord = // input CKRecord
let objc: SomeType = try CKRecordDecoder().decode(from: record)
```

## License

CKCodable is available under the MIT license. See the LICENSE file for more info.
