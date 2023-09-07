//
//  App.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import Foundation
import BrewCore
import SwiftData
import BrewShared

@MainActor
final class Dependencies {
    let modelContainer: ModelContainer
    let search: BrewSearchService
    let brewService: BrewService
    let api: BrewApi

    init() async throws {
        let container = try ModelContainer(
            for: PackageCache.self, InstalledCache.self, OutdatedCache.self, UpdateCache.self,
            configurations: ModelConfiguration(url: .brewStorage)
        )
        self.modelContainer = container
        let cache = try await BrewCache(container: container)
        api = BrewApi()
        brewService = BrewService(cache: cache, api: api)

        search = BrewSearchService(cache: cache, service: brewService)
    }

    private static var sharedTask: Task<Dependencies, Error>?

    static func shared() async throws -> Dependencies {
        if let sharedTask {
            return try await sharedTask.value
        }
        let depsTask = Task {
            try await Dependencies()
        }
        sharedTask = depsTask
        return try await depsTask.value
    }
}