//
//  Dependencies.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import BrewCore
import BrewShared
import Foundation
import SwiftData

@MainActor
final class Dependencies {
    let modelContainer: ModelContainer
    let search: BrewSearchService
    let processService: BrewProcessService
    let brewService: BrewService
    let api: BrewApi
    let updateService: BrewUpdateService

    init() async throws {
        let container = try ModelContainer(
            for: PackageCache.self, InstalledCache.self, OutdatedCache.self, UpdateCache.self,
            configurations: ModelConfiguration("BrewUIDB", url: .brewStorage)
        )
        modelContainer = container
        let cache = try await BrewCache(container: container)
        api = BrewApi()
        processService = BrewProcessService()
        brewService = BrewService(cache: cache, api: api, processService: processService)

        search = BrewSearchService(
            cache: cache,
            service: brewService,
            processService: processService
        )

        updateService = BrewUpdateService(
            service: brewService,
            processService: processService
        )
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
