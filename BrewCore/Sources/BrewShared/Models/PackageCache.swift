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
    public internal(set) var jsonRemote: Data

    public internal(set) var lastUpdated: Date
    public internal(set) var checksum: String
    public internal(set) var sortValue: String
    public internal(set) var outdated: Bool
    public internal(set) var installedVersion: String?
    public internal(set) var installedAsDependency: Bool
    public internal(set) var installedOther: String?

    public internal(set) var versionsStable: String?
    public internal(set) var versionsHead: String?

    public internal(set) var license: String?
    public internal(set) var homepage: String

    public internal(set) var baseName: String
    public internal(set) var tap: String
    public internal(set) var desc: String

    public init(info: InfoResult, encoder: JSONEncoder = .init()) throws {
        encoder.outputFormatting.insert(.sortedKeys)

        self.identifier = info.identifier.description
        self.sortValue = "\(info.identifier.name)--\(info.identifier.tap)"

        self.checksum = info.rubySourceChecksum.sha256

        self.jsonRemote = try encoder.encode(info.onlyRemote)
        self.json = try encoder.encode(info)

        self.outdated = false

        self.homepage = info.homepage
        self.baseName = info.identifier.name

        self.tap = info.identifier.tap

        self.desc = info.desc ?? ""

        self.versionsHead = info.versions.head
        self.versionsStable = info.versions.stable ?? info.versions.head ?? ""

        self.license = info.license

        self.lastUpdated = .now

        self.installedAsDependency = info.installedAsDependency
    }

    public init(info: InfoResultOnlyRemote, encoder: JSONEncoder = .init()) throws {
        encoder.outputFormatting.insert(.sortedKeys)

        self.identifier = info.identifier.description
        self.sortValue = "\(info.identifier.name)--\(info.identifier.tap)"

        self.checksum = ""

        self.jsonRemote = try encoder.encode(info)
        self.json = Data()

        self.outdated = false

        self.homepage = info.homepage
        self.baseName = info.identifier.name

        self.tap = info.identifier.tap

        self.desc = info.desc ?? ""

        self.versionsHead = info.versions.head
        self.versionsStable = info.versions.stable ?? info.versions.head ?? ""

        self.license = info.license

        self.lastUpdated = .now

        self.installedAsDependency = false
    }

    public func update(infoRemote info: InfoResultOnlyRemote, encoder: JSONEncoder = .init()) throws {
        encoder.outputFormatting.insert(.sortedKeys)

        var isChanged = false

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

        let json = try encoder.encode(info)
        if jsonRemote != json {
            isChanged = true

            jsonRemote = json
        }

        if isChanged {
            lastUpdated = .now
        }
    }

    public func update(info: InfoResult, encoder: JSONEncoder = .init()) throws {
        encoder.outputFormatting.insert(.sortedKeys)

        var isChanged = false

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

        let json = try encoder.encode(info)
        if self.json != json {
            isChanged = true

            self.json = json
        }

        if isChanged {
            lastUpdated = .now
        }

        try update(infoRemote: info.onlyRemote)
    }
}

extension PackageCache: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(json)
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
