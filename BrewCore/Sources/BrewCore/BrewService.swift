//
//  BrewService.swift
//  BrewUI
//
//  Created by Tomas Harkema on 05/05/2023.
//

// swiftlint:disable identifier_name

import Combine
import Foundation
import RawJson
import SwiftData
import SwiftUI
import SwiftTracing
import BrewShared

public final class BrewService: ObservableObject {
    private static let listRegex = /(.+) (.+)/

    public let cache: BrewCache
    public let api: BrewApi

    public init(cache: BrewCache, api: BrewApi) {
        self.cache = cache
        self.api = api
    }

    private nonisolated func executeBrew(command: String) async throws -> String {
        return try await BrewProcess.shell(command: "\(command)")
    }

    @UpdateActor
    private var updateTask: Task<Void, Error>?

    @UpdateActor
    public func update() async throws {
        if let updateTask {
          return try await updateTask.value
        }

        let updateTask = Task {
            do {
                _ = try await executeBrew(command: "update")
                _ = try await fetchInfo()
                print("UPDATE DONE!")
            } catch {
                print("ERROR", error)
                throw error
            }
        }

        self.updateTask = updateTask
        defer {
          self.updateTask = nil
        }

        try await updateTask.value
    }

    @UpdateActor
    private var fetchInfoTask: Task<[InfoResult], Error>?

    @UpdateActor
    public func fetchInfo() async throws -> [InfoResult] {
        if let fetchInfoTask {
            return try await fetchInfoTask.value
        }

        let resultTask = Task {
            let formulaResult = try await api.formula()
            let formula = formulaResult.compactMap(\.value)
            try await cache.sync(all: formula)
            return formula
        }

        let installedTask = Task {
            _ = try? await resultTask.value
            let info = try await self.executeBrew(command: "info --json=v1 --installed")

            let installed = try JSONDecoder().decode(
                [FallbackCodable<InfoResult>].self,
                from: info.data(using: .utf8)!
            ).compactMap(\.value)
            return installed
        }

        let installedSyncTask = Task {
            try await cache.sync(installed: installedTask.value)
        }

        let outdatedTask = Task {
            let outdated = try await installedTask.value.filter(\.outdated)
            try await cache.sync(outdated: outdated)
        }

        let fetchInfoTask = Task {
            let date = Date()

            let (res, _, _, _) = try await (resultTask.value, installedTask.value, installedSyncTask.value, outdatedTask.value)   //, outdatedTask.value)

            print("timetaken", abs(date.timeIntervalSinceNow))
            return res
        }

        self.fetchInfoTask = fetchInfoTask
        defer {
            self.fetchInfoTask = nil
        }

        return try await fetchInfoTask.value
    }

//    func list(cask: Bool) async throws -> [ListResult] {
//        let caskFlag = cask ? " --cask" : ""
//
//        let result = try await executeBrew(command: "list --versions\(caskFlag)")
//
//        return result.matches(of: listRegex).map {
//            ListResult(
//                name: $0.output.1.trimmingCharacters(in: .whitespacesAndNewlines),
//                version: $0.output.2.trimmingCharacters(in: .whitespacesAndNewlines)
////        cask: cask
//            )
//        }
//    }

    public nonisolated func searchFormula(query: String) async throws -> [PackageIdentifier] {
        let stream = try await BrewProcess.shell(command: "search --formula \(query)")

        return try stream.split(separator: "\n")
            .compactMap {
                try PackageIdentifier(raw: String($0))
            }
    }

    nonisolated func infoFormula(package: PackageIdentifier) async throws -> [InfoResult] {
        let stream = try await BrewProcess.shell(command: "info --json=v1 --formula \(package.nameWithoutCore)")

        guard let data = stream.data(using: .utf8) else {
            return []
        }
        do {
            return try JSONDecoder().decode([InfoResult].self, from: data)
        } catch {
            print(error)
            throw error
        }
    }

    public nonisolated func install(name: PackageIdentifier) async throws -> BrewStreaming {
        return try await BrewStreaming.install(service: self, name: name)
    }

    public nonisolated func uninstall(name: PackageIdentifier) async throws -> BrewStreaming {
        return try await BrewStreaming.uninstall(service: self, name: name)
    }

    public nonisolated func upgrade(name: PackageIdentifier) async throws -> BrewStreaming {
        return try await BrewStreaming.upgrade(service: self, name: name)
    }
}

public struct StdErr: Error {
    public let stdout: String
    public let stderr: String
    public let command: String

    init(stdout: String, stderr: String, command: String) {
        self.stdout = stdout
        self.stderr = stderr
        self.command = command
    }

    init(stream: [StreamElement], command: String) {
        stdout = stream.lazy.filter {
            $0.level == .out
        }
        .map { $0.rawEntry }
        .joined(separator: "\n")
        stderr = stream.lazy.filter {
            $0.level == .err
        }
        .map { $0.rawEntry }
        .joined(separator: "\n")
        self.command = command
    }
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

@globalActor
actor SearchActor {
    static let shared = SearchActor()

    static func run<T>(
        resultType _: T.Type = T.self,
        body: @SearchActor @Sendable () async throws -> T
    ) async rethrows -> T where T: Sendable {
        try await body()
    }
}

@globalActor
public actor UpdateActor {
    public static let shared = UpdateActor()
    public static func run<T>(
        resultType _: T.Type = T.self,
        body: @UpdateActor @Sendable () async throws -> T
    ) async rethrows -> T where T: Sendable {
        try await body()
    }
}

@globalActor
public actor BrewActor {
    public static let shared = BrewActor()
}

struct Brew: RawRepresentable {
    let rawValue: String
}

// swiftlint:enable identifier_name
