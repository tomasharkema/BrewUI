//
//  InstalledCache.swift
//
//
//  Created by Tomas Harkema on 04/10/2023.
//

import Foundation
import SwiftData

@Model
public final class InstalledCache: PackageCachable {
    @Attribute
    public var package: PackageCache!
    @Attribute
    public var lastUpdated: Date
    @Attribute(.unique)
    public var identifier: PackageIdentifierString
    //    @Attribute
    //    public var sortValue: String {
    //        package.sortValue
    //    }

    private init() {
        package = nil
        lastUpdated = .now
        identifier = ""
    }

    public static func create(package: PackageCache) -> InstalledCache {
        let cached = InstalledCache()
        cached.package = package
        cached.lastUpdated = .now
        cached.identifier = package.identifier
        return cached
    }
}

extension InstalledCache: Identifiable {
    public var id: PackageIdentifier {
        package.id
    }
}
