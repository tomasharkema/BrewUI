//
//  PackageCache.swift
//  BrewUI
//
//  Created by Tomas Harkema on 31/08/2023.
//

import Foundation
import SwiftData
import SwiftUI

public typealias PackageIdentifierString = String

@Model
public final class PackageCache {
    @Attribute(.unique)
    public internal(set) var identifier: PackageIdentifierString

    public internal(set) var json: Data
    public internal(set) var lastUpdated: Date
    public internal(set) var checksum: String
    public internal(set) var sortValue: String
    public internal(set) var outdated: Bool
    public internal(set) var installedVersion: String?
    public internal(set) var installedAsDependency: Bool?
    public internal(set) var installedOther: String?

    public internal(set) var versionsStable: String
    public internal(set) var versionsHead: String?

    public internal(set) var license: String?
    public internal(set) var homepage: String

    public internal(set) var baseName: String
    public internal(set) var tap: String
    public internal(set) var desc: String

    public init(
        identifier: PackageIdentifier, checksum: String, json: Data,
        homepage: String, versionsStable: String, desc: String,
        lastUpdated: Date = .now
    ) {
        self.identifier = identifier.description
        sortValue = "\(identifier.name)--\(identifier.tap)"
        self.checksum = checksum
        self.json = json
        self.lastUpdated = lastUpdated
        outdated = false
        self.lastUpdated = lastUpdated
        self.homepage = homepage
        baseName = identifier.name
        tap = identifier.tap
        self.versionsStable = versionsStable
        self.desc = desc
    }

    public func update(info: InfoResult, isLocal: Bool) {
        var isChanged = false

        if isLocal {
            if outdated != info.outdated {
                outdated = info.outdated
                isChanged = true
            }
            if installedVersion != info.installedVersion {
                installedVersion = info.installedVersion
                isChanged = true
            }
            if installedAsDependency != info.installedAsDependency {
                installedAsDependency = info.installedAsDependency
                isChanged = true
            }
//            if installedOther != info.installedOther {
//                installedOther = info.installedOther
//                isChanged = true
//            }
        }

        let newVersionsStable = info.versions.stable ?? info.versions.head ?? ""
        if versionsStable != newVersionsStable {
            versionsStable = newVersionsStable
            isChanged = true
        }

        if versionsHead != info.versions.head {
            versionsHead = info.versions.head
            isChanged = true
        }

        if license != info.license {
            license = info.license
            isChanged = true
        }
        if homepage != info.homepage {
            homepage = info.homepage
            isChanged = true
        }
        if desc != info.desc ?? "" {
            desc = info.desc ?? ""
            isChanged = true
        }

        if isChanged {
            lastUpdated = .now
        }
    }
}

public protocol PackageCachable {
    var identifier: PackageIdentifierString { get }
    var package: PackageCache! { get set }
    var lastUpdated: Date { get set }
}

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

@Model
public final class OutdatedCache: PackageCachable {
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

    public static func create(package: PackageCache) -> OutdatedCache {
        let cached = OutdatedCache()
        cached.package = package
        cached.lastUpdated = .now
        cached.identifier = package.identifier
        return cached
    }
}

@Model
public final class UpdateCache: PackageCachable {
    public var package: PackageCache!
    public var lastUpdated: Date

    @Attribute(.unique)
    public var identifier: PackageIdentifierString

    private init() {
        package = nil
        lastUpdated = .now
        identifier = ""
    }

    public static func create(package: PackageCache) -> UpdateCache {
        let cached = UpdateCache()
        cached.package = package
        cached.lastUpdated = .now
        cached.identifier = package.identifier
        return cached
    }
}

extension OutdatedCache: Identifiable {
    public var id: PackageIdentifier {
        package.id
    }
}

extension PackageCache: Identifiable {
    public var id: PackageIdentifier {
        PackageIdentifier(tap: tap, name: baseName)
    }
}

extension UpdateCache: Identifiable {
    public var id: PackageIdentifier {
        package.id
    }
}

extension InstalledCache: Identifiable {
    public var id: PackageIdentifier {
        package.id
    }
}
