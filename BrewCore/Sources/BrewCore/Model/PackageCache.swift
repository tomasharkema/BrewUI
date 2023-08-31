//
//  PackageCache.swift
//  BrewUI
//
//  Created by Tomas Harkema on 31/08/2023.
//

import Foundation
import SwiftData
import SwiftUI

@Model
public final class PackageCache {
    @Attribute(.unique) public var name: PackageIdentifier.RawValue

    var json: Data
    var lastUpdated: Date

    init(name: PackageIdentifier, json: Data, lastUpdated: Date = .now) {
        self.name = name.rawValue
        self.json = json
        self.lastUpdated = lastUpdated
    }

    @Transient
    public var result: InfoResult? {
//        #if DEBUG
//        dispatchPrecondition(condition: .notOnQueue(.main))
//        #endif
        return try? JSONDecoder().decode(InfoResult.self, from: json)
    }
}

public protocol PackageCachable {
    var name: PackageIdentifier.RawValue { get }
    var package: PackageCache! { get set }
    var lastUpdated: Date { get set }
}

@Model
public final class InstalledCache: PackageCachable {
    public var package: PackageCache!
    public var lastUpdated: Date
    public var name: PackageIdentifier.RawValue

    private init() {
        package = nil
        lastUpdated = .now
        name = ""
    }

    static func create(package: PackageCache) -> InstalledCache {
        let c = InstalledCache()
        c.package = package
        c.lastUpdated = .now
        c.name = package.name
        return c
    }
}

@Model
public final class OutdatedCache: PackageCachable {
    public var package: PackageCache!
    public var lastUpdated: Date
    public var name: PackageIdentifier.RawValue

    private init() {
        package = nil
        lastUpdated = .now
        name = ""
    }

    static func create(package: PackageCache) -> OutdatedCache {
        let c = OutdatedCache()
        c.package = package
        c.lastUpdated = .now
        c.name = package.name
        return c
    }
}

@Model
public final class UpdateCache: PackageCachable {
    public var package: PackageCache!
    public var lastUpdated: Date
    public var name: PackageIdentifier.RawValue

    private init() {
        package = nil
        lastUpdated = .now
        name = ""
    }

    static func create(package: PackageCache) -> UpdateCache {
        let c = UpdateCache()
        c.package = package
        c.lastUpdated = .now
        c.name = package.name
        return c
    }
}

extension PackageCachable {
    public var result: InfoResult? {
        package.result
    }
}

extension OutdatedCache: Identifiable {
    public var id: PackageIdentifier {
        package.id
    }
}

extension PackageCache: Identifiable {
    public var id: PackageIdentifier {
        PackageIdentifier(rawValue: name)
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
