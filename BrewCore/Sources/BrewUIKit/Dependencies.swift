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
//    let search: BrewSearchService
//    let processService: BrewProcessService
//    let brewService: BrewService
//    let api: BrewApi
    let updateService: BrewUpdateService

    init() async throws {
        modelContainer = .brew

        updateService = BrewUpdateService()
//        let cache = try await BrewCache()
//        let api = BrewApi()
//        let processService = BrewProcessService()
//        let brewService = BrewService()
//
//        let search = BrewSearchService()
//
//        let updateService = BrewUpdateService()
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
