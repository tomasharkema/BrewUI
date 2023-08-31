//
//  BrewCache.swift
//  
//
//  Created by Tomas Harkema on 01/09/2023.
//

import Foundation
import SwiftData
import SwiftUI

public actor BrewCache: ModelActor {
    public let modelExecutor: ModelExecutor
    public nonisolated let modelContainer: ModelContainer

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
