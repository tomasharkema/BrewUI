//
//  PackageIdentifierTransformer.swift
//  
//
//  Created by Tomas Harkema on 03/09/2023.
//

import Foundation


@objc(PackageIdentifierTransformer)
class PackageIdentifierTransformer: ValueTransformer {

    override func transformedValue(_ value: Any?) -> Any? {
        let boxedData = try! NSKeyedArchiver.archivedData(withRootObject: value!, requiringSecureCoding: true)
        return boxedData
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        let typedBlob = value as! Data
        let data = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSString.self], from: typedBlob)
        return (data as! String)
    }

}

extension NSValueTransformerName {
    static let packageIdentifierTransformerName = Self.init("packageIdentifierTransformerName")
}
