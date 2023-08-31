//
//  PackageCache.swift
//  BrewUI
//
//  Created by Tomas Harkema on 31/08/2023.
//

import Foundation
import SwiftData
import SwiftUI

actor BrewCache: ModelActor {
    let modelExecutor: ModelExecutor
    nonisolated let modelContainer: ModelContainer

    init() {

        #if DEBUG
        let url = URL.documentsDirectory.appending(path: "brewui_debug.store")
        #else
        let url = URL.documentsDirectory.appending(path: "brewui.store")
        #endif

        let container = try! ModelContainer(for: Schema([
            PackageCache.self, InstalledCache.self, OutdatedCache.self, UpdateCache.self,
        ]), configurations: ModelConfiguration(url: url))

        modelContainer = container
        let context = ModelContext(container)
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }

    func sync(all: [InfoResult]) throws {
        for pkg in all {
            _ = try packageGetOrCreate(info: pkg)
            try modelContext.save()
        }
    }

    func sync(outdated: [InfoResult]) throws {
        try modelContext.transaction {
            try modelContext.delete(model: OutdatedCache.self, where: .true)

            for pkg in outdated {
                let package = try self.packageGetOrCreate(info: pkg)
                let installed = OutdatedCache.create(package: package)
                modelContext.insert(installed)
            }
        }
    }

    func sync(installed: [InfoResult]) throws {
        try modelContext.transaction {
            try modelContext.delete(model: InstalledCache.self, where: .true)

            for pkg in installed {
                let package = try self.packageGetOrCreate(info: pkg)
                let installed = InstalledCache.create(package: package)
                modelContext.insert(installed)
            }
        }
    }

    func package(by name: PackageIdentifier) throws -> PackageCache? {
        var descriptor = FetchDescriptor<PackageCache>()
        descriptor.predicate = #Predicate {
            $0.name == name.rawValue
        }
        return try modelContext.fetch(descriptor).first
    }

    func packageGetOrCreate(info: InfoResult) throws -> PackageCache {
        if let res = try package(by: info.full_name) {
            return res
        }

        let json = try JSONEncoder().encode(info)
        let package = PackageCache(name: info.full_name, json: json)
        modelContext.insert(package)
        return package
    }
}

// @objc(PackageIdentifierTransformable)
// class PackageIdentifierTransformable: ValueTransformer {
//    class override func transformedValueClass() -> AnyClass {
//        NSString.self
//    }
//
//    class override func allowsReverseTransformation() -> Bool {
//        return true
//    }
//
//    override func transformedValue(_ value: Any?) -> Any? {
//        return value
//    }
//
//    override func reverseTransformedValue(_ value: Any?) -> Any? {
//        return value
//    }
// }

@Model
final class PackageCache {
    @Attribute(.unique)
    var name: PackageIdentifier.RawValue

    var json: Data
    var lastUpdated: Date

    init(name: PackageIdentifier, json: Data, lastUpdated: Date = .now) {
        self.name = name.rawValue
        self.json = json
        self.lastUpdated = lastUpdated
    }

    @Transient
    var result: InfoResult? {
        try? JSONDecoder().decode(InfoResult.self, from: json)
    }
}

extension PackageCache: Identifiable {
    var id: PackageIdentifier {
        PackageIdentifier(rawValue: name)
    }
}

@Model
final class InstalledCache {
    var package: PackageCache!
    var lastUpdated: Date!

    private init() {
        package = nil
        lastUpdated = .now
    }

    static func create(package: PackageCache) -> InstalledCache {
        let c = InstalledCache()
        c.package = package
        c.lastUpdated = .now
        return c
    }

    @Transient
    var result: InfoResult? {
        package.result
    }
}

extension InstalledCache: Identifiable {
    var id: PackageIdentifier {
        package.id
    }
}

@Model
final class OutdatedCache {
    var package: PackageCache!
    var lastUpdated: Date!

    private init() {
        package = nil
        lastUpdated = .now
    }

    static func create(package: PackageCache) -> OutdatedCache {
        let c = OutdatedCache()
        c.package = package
        c.lastUpdated = .now
        return c
    }

    @Transient
    var result: InfoResult? {
        package.result
    }
}

extension OutdatedCache: Identifiable {
    var id: PackageIdentifier {
        package.id
    }
}

@Model
final class UpdateCache {
    var package: PackageCache!
    var lastUpdated: Date!

    private init() {
        package = nil
        lastUpdated = .now
    }

    static func create(package: PackageCache) -> UpdateCache {
        let c = UpdateCache()
        c.package = package
        c.lastUpdated = .now
        return c
    }

    @Transient
    var result: InfoResult? {
        package.result
    }
}

extension UpdateCache: Identifiable {
    var id: PackageIdentifier {
        package.id
    }
}
