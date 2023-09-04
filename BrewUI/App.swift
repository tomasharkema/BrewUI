//
//  App.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import Foundation
import BrewCore
import SwiftData

final class Dependencies: Sendable {
    let modelContainer: ModelContainer
    let search: BrewSearchService
    let brewService: BrewService

    init() async throws {
        let baseFolder = URL.applicationSupportDirectory
        let workingFolder = baseFolder.appending(path: "brewui")

        if !FileManager.default.fileExists(atPath: workingFolder.path) {
            try FileManager.default.createDirectory(at: workingFolder, withIntermediateDirectories: false)
        }

#if DEBUG
        let url = workingFolder.appending(path: "brewui_debug.store")
#else
        let url = workingFolder.appending(path: "brewui.store")
#endif

        let container = try ModelContainer.brew(url: url)
        self.modelContainer = container
        let cache = try await Task { @UpdateActor in
            let newCache = try BrewCache(container: container)
            print(newCache)
            return newCache
        }.value
        brewService = await BrewService(cache: cache)

        search = await BrewSearchService(cache: cache, service: brewService)
    }

    @MainActor
    private static var sharedTask: Task<Dependencies, Never>?

    @MainActor
    static func shared() async -> Dependencies {
        if let sharedTask {
            return await sharedTask.value
        }
        let s = Task {
            try! await Dependencies()
        }
        sharedTask = s
        return await s.value
    }
}
