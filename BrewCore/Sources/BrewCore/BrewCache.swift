//
//  BrewCache.swift
//
//
//  Created by Tomas Harkema on 01/09/2023.
//

import Algorithms
import BrewShared
import Foundation
import SwiftData
import SwiftUI

public struct Differ<InputType: Hashable & Identifiable, OutputType: Hashable & Identifiable>
where InputType.ID == OutputType.ID {

    private let old: Set<InputType>
    private let new: Set<OutputType>

    let adds: Set<InputType.ID>
    let removes: Set<InputType.ID>
    let updates: Set<InputType.ID>

    private let oldDict: [InputType.ID: InputType]
    private let newDict: [InputType.ID: OutputType]

    init(old: Set<InputType>, new: Set<OutputType>) {
        self.old = old
        self.new = new

        let oldDict = Dictionary(old.map { ($0.id, $0) }, uniquingKeysWith: { (first, _) in first })
        let newDict = Dictionary(new.map { ($0.id, $0) }, uniquingKeysWith: { (first, _) in first })

        let oldIds = Set(oldDict.keys)
        let newIds = Set(newDict.keys)

        adds = newIds.subtracting(oldIds)
        removes = oldIds.subtracting(newIds)

        let unions = newIds.union(oldIds)

        let updates: Set<InputType.ID> = Set(unions.compactMap { id in
            guard let oldItem = oldDict[id] else {
                return nil
            }
            guard let newItem = newDict[id] else {
                return nil
            }
            guard oldItem.hashValue != newItem.hashValue else {
                return nil
            }
            return newItem.id
        })

        self.updates = updates
        self.oldDict = oldDict
        self.newDict = newDict
    }

    func element(_ id: InputType.ID) -> OutputType? {
        newDict[id]
    }
}

extension Differ {
    init(old: any Sequence<InputType>, new: any Sequence<OutputType>) {
        self.init(old: Set(old), new: Set(new))
    }
}

public actor BrewCache: ModelActor {
    public static let globalFetchLimit = 100
    public let modelExecutor: any ModelExecutor
    public nonisolated let modelContainer: ModelContainer

    public nonisolated init(container: ModelContainer) async throws {
        #if DEBUG
            dispatchPrecondition(condition: .notOnQueue(.main))
        #endif

        modelContainer = container
        let context = ModelContext(container)
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }

    public func sync(all: [InfoResultOnlyRemote]) throws {
        guard !all.isEmpty else {
            return
        }

        let core = PackageIdentifier.core
        let old = try self.modelContext.fetch(
            FetchDescriptor<PackageCache>(predicate: #Predicate { $0.tap == core })
        ).lazy.map {
            PackageCacheRemoteWrapper(package: $0)
        }

        let diff = Differ(old: old, new: all)

        if !diff.updates.isEmpty {
            print("UPDATED!")
        }

        try modelContext.transaction {

            for add in diff.adds {
                let item = diff.element(add)!
                modelContext.insert(try PackageCache(info: item))
            }

            if !diff.removes.isEmpty {
                let ids = diff.removes.map(\.id.description)
                try modelContext.delete(model: PackageCache.self, where: #Predicate {
                    ids.contains($0.identifier)
                })
            }

            for update in diff.updates {
                if let model = try self.package(by: update.id) {
                    try model.update(infoRemote: diff.element(update.id)!)
                }
            }
        }
    }

    public func sync(outdated: [InfoResult]) throws {

        let old = try self.modelContext.fetch(
            FetchDescriptor<OutdatedCache>()
        )

        let diff = Differ(old: old, new: outdated)

        try modelContext.transaction {
            for add in diff.adds {
                let info = diff.element(add)!
                let model = try package(by: info.identifier)
//                let package = try self.packageGetOrCreate(info: info)
                let installed = OutdatedCache.create(package: model!)
                modelContext.insert(installed)
            }

            if !diff.removes.isEmpty {
                let ids = diff.removes.map(\.id.description)
                try modelContext.delete(model: OutdatedCache.self, where: #Predicate {
                    ids.contains($0.identifier)
                })
            }
        }
    }

    public func sync(installed: [InfoResult]) throws -> [InfoResult] {

        let old = try self.modelContext.fetch(
            FetchDescriptor<InstalledCache>()
        )
        let oldSet = Set(old)
        let allSet = Set(installed)

        let diff = Differ(old: oldSet, new: allSet)

        try modelContext.transaction {

            for add in diff.adds {
                let model = try self.packageGetOrCreate(info: diff.element(add.id)!)
                let installed = InstalledCache.create(package: model)
                modelContext.insert(installed)
            }
            
            if !diff.removes.isEmpty {
                let idDescription = diff.removes.map(\.id.description)
                try modelContext.delete(model: InstalledCache.self, where: #Predicate {
                    idDescription.contains($0.identifier)
                })
            }
        }
        return installed
    }

    public func sync(taps: [TapInfo]) throws {
        try modelContext.transaction {
            let old = try self.modelContext.fetch(FetchDescriptor<Tap>())

            let diff = Differ(old: old, new: taps)

            if !diff.updates.isEmpty {
                print("UPDATED!")
            }

            for tap in diff.adds {
                let tapInfo = diff.element(tap)!

                let tapModel = try self.tap(by: tap) ?? Tap(info: tapInfo)
                tapModel.name = tapInfo.name
                tapModel.user = tapInfo.user
                tapModel.repo = tapInfo.repo
                tapModel.path = tapInfo.path
                tapModel.installed = tapInfo.installed
                tapModel.official = tapInfo.official
                tapModel.remote = tapInfo.remote

                modelContext.insert(tapModel)
            }

            if !diff.removes.isEmpty {
                let removes = diff.removes
                try modelContext.delete(model: Tap.self, where: #Predicate {
                    removes.contains($0.name)
                })
            }
        }
    }

    public func tap(by name: String) throws -> Tap? {
        var descriptor = FetchDescriptor<Tap>()
        descriptor.predicate = #Predicate {
            $0.name == name
        }
        return try modelContext.fetch(descriptor).first
    }

    public func package(by name: PackageIdentifier) throws -> PackageCache? {
        var descriptor = FetchDescriptor<PackageCache>()
        descriptor.predicate = #Predicate {
            $0.identifier == name.description
        }
        return try modelContext.fetch(descriptor).first
    }

    public func packageGetOrCreate(info: InfoResult) throws -> PackageCache {
        if let model = try package(by: info.identifier) {
            try model.update(info: info)
            return model
        }

        let model = try PackageCache(info: info)
        try model.update(info: info)
        modelContext.insert(model)
        return model
    }

    public func packageGetOrCreate(info: InfoResultOnlyRemote) throws -> PackageCache {
        if let model = try package(by: info.identifier) {
            try model.update(infoRemote: info)
            return model
        }

        let model = try PackageCache(info: info)
        try model.update(infoRemote: info)
        modelContext.insert(model)
        return model
    }

    public func search(query: String) throws -> [PackageCache] {
        var descriptor = FetchDescriptor<PackageCache>()
        descriptor.predicate = #Predicate {
            $0.identifier.contains(query) || $0.desc.contains(query)
        }
        return try modelContext.fetch(descriptor)
    }
}
