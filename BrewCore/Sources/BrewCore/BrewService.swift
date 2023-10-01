//
//  BrewService.swift
//  BrewUI
//
//  Created by Tomas Harkema on 05/05/2023.
//

import BrewHelpers
import BrewShared
import Combine
import Foundation
import OSLog
import RawJson
import SwiftData
import SwiftTracing
import SwiftUI

public final class BrewService: ObservableObject {
    private let cache: BrewCache
    private let api: BrewApi
    private let processService: BrewProcessService

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BrewService")

    public init(cache: BrewCache, api: BrewApi, processService: BrewProcessService) {
        self.cache = cache
        self.api = api
        self.processService = processService
    }

    public func fetchInfo() async throws {
        try await EnsureOnce.once {
            let resultTask = Task {
                let formulaResult = try await self.api.formula()
                let formula = formulaResult.compactMap(\.value)
                try await self.cache.sync(all: formula)
                return formula
            }

            let installedTask = Task {
                _ = try? await resultTask.value
                return try await self.processService.infoFormulaInstalled()
            }

            let installedSyncTask = Task {
                try await self.cache.sync(installed: installedTask.value)
            }

            let outdatedTask = Task {
                let outdated = try await installedTask.value.filter(\.outdated)
                try await self.cache.sync(outdated: outdated)
            }

            let date = Date()

            //            async let list = self.listFormula()

            let _ = try await (
                resultTask.value, installedTask.value, installedSyncTask.value, outdatedTask.value
            )
            //            print(listthing)
            self.logger.info("timetaken \(abs(date.timeIntervalSinceNow))")
//            return res
        }
    }

    static func parseListVersions(input: String) -> [ListResult] {
        let matches = input.matches(of: /(\S+) (\S+)/)
        return matches.map {
            ListResult(name: String($0.output.1), version: String($0.output.2))
        }
    }

    nonisolated func listFormula() async throws -> [ListResult] {
        let listResult = try await processService.shell(command: .list(.versions))
        return Self.parseListVersions(input: listResult.outString)
    }

    nonisolated func install(name: PackageIdentifier) async throws -> BrewStreaming {
        try await BrewStreaming.install(service: self, processService: processService, name: name)
    }

    nonisolated func uninstall(name: PackageIdentifier) async throws -> BrewStreaming {
        try await BrewStreaming.uninstall(service: self, processService: processService, name: name)
    }

    nonisolated func upgrade(name: PackageIdentifier) async throws -> BrewStreaming {
        try await BrewStreaming.upgrade(service: self, processService: processService, name: name)
    }

    nonisolated func upgrade() async throws -> BrewStreaming {
        try await BrewStreaming.upgrade(service: self, processService: processService)
    }

//    public nonisolated func searchFormula(query: String) async throws -> [PackageIdentifier] {
//        return try await process.searchFormula(query: query)
//    }
//
//    nonisolated func infoFormula(package: PackageIdentifier) async throws -> [InfoResult] {
//        return try await process.infoFormula(package: package)
//    }
}

struct StreamOutput: Hashable {
    var stream: String
    var isStreamingDone: Bool
}

extension StreamOutput: Identifiable {
    var id: Int {
        hashValue
    }
}

struct Brew: RawRepresentable {
    let rawValue: String
}
