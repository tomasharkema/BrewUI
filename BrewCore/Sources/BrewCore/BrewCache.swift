//
//  BrewCache.swift
//  
//
//  Created by Tomas Harkema on 01/09/2023.
//

import Foundation
import SwiftData
import SwiftUI
import Algorithms

public actor BrewCache: ModelActor {
    public static let globalFetchLimit = 100
    public let modelExecutor: ModelExecutor
    public nonisolated let modelContainer: ModelContainer

    public init(container: ModelContainer) throws {
        dispatchPrecondition(condition: .notOnQueue(.main))

        modelContainer = container
        let context = ModelContext(container)
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }

    public func sync(all: [InfoResult]) throws {
        guard !all.isEmpty else {
            return
        }
        check()

        for pkgs in all.chunks(ofCount: 100) {
            try modelContext.transaction {
                for pkg in pkgs {
                    _ = try packageGetOrCreate(info: pkg, isLocal: false)
                }
            }
        }
    }

    func sync(outdated: [InfoResult]) throws {
        check()

        try modelContext.transaction {
            try modelContext.delete(model: OutdatedCache.self, where: .true)

            for pkg in outdated {
                let package = try self.packageGetOrCreate(info: pkg, isLocal: true)
                let installed = OutdatedCache.create(package: package)
                modelContext.insert(installed)
            }
        }
    }

    func sync(installed: [InfoResult]) throws {
        check()

        try modelContext.transaction {
            try modelContext.delete(model: InstalledCache.self, where: .true)

            for pkg in installed {
                let package = try self.packageGetOrCreate(info: pkg, isLocal: true)
                let installed = InstalledCache.create(package: package)
                modelContext.insert(installed)
            }
        }
    }

    func package(by name: PackageIdentifier) throws -> PackageCache? {
        check()

        var descriptor = FetchDescriptor<PackageCache>()
        descriptor.predicate = #Predicate {
            $0.identifier == name.description
        }
        return try! modelContext.fetch(descriptor).first
    }

    func packageGetOrCreate(info: InfoResult, isLocal: Bool) throws -> PackageCache {
        check()

        if let model = try package(by: info.identifier) {
            model.update(info: info, isLocal: isLocal)
            return model
        }

        let json = try JSONEncoder().encode(info)
        let model = PackageCache(
            identifier: info.identifier,
            checksum: info.ruby_source_checksum.sha256,
            json: json, homepage: info.homepage,
            versionsStable: info.versionsStable ?? info.versions.head ?? "",
            desc: info.desc ?? ""
        )
        model.update(info: info, isLocal: isLocal)
        modelContext.insert(model)
        return model
    }

    func search(query: String) throws -> [PackageCache] {
        var descriptor = FetchDescriptor<PackageCache>()
        descriptor.predicate = #Predicate {
            $0.identifier.contains(query) || $0.desc.contains(query)
        }
        return try modelContext.fetch(descriptor)
    }

    private func check() {
        #if DEBUG
        assertIsolated()
        dispatchPrecondition(condition: .notOnQueue(.main))
        #endif
    }
}
