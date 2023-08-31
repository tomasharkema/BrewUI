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

@MainActor
public final class BrewService: ObservableObject {
    public static let shared = BrewService()
    public let cache = BrewCache()

    @Query var cacheInstalled: [InstalledCache]
    @Published public var queryResult: InfoResultSort?
    private var streamCancellable: AnyCancellable?
    @Published public var stream: StreamStreamingAndTask?
    @Published private var updateTask: Task<Void, Error>?
    var isUpdateRunning: Bool {
        updateTask != nil
    }

    private let listRegex = /(.+) (.+)/

    func whichBrew() async throws -> String {
        let result = try await (Process.shell(command: "which brew"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        print("FOUND BREW: \(result)")
        return result
    }

    func executeBrew(command: String) async throws -> String {
        let brew = try await whichBrew()
        return try await Process.shell(command: "\(brew) \(command)")
    }

    @UpdateActor
    public func update() async throws {
//    if let updateTask {
//      return try await updateTask.value
//    }
        do {
            _ = try await executeBrew(command: "update")
            _ = try await fetchInfo()
            print("UPDATE DONE!")
        } catch {
            print("ERROR", error)
            throw error
        }

//    self.updateTask = updateTask
//    defer {
//      self.updateTask = nil
//    }

//    try await updateTask.value
    }

    @UpdateActor
    public func fetchInfo() async throws -> [InfoResult] {
        let info = try await executeBrew(command: "info --json=v1 --eval-all")

        let result = try JSONDecoder().decode(
            [FallbackCodable<InfoResult>].self,
            from: info.data(using: .utf8)!
        )
        .compactMap(\.value)

        let installed = Task {
            result.filter {
                !$0.installed.isEmpty
            }
        }

        let resultTask = Task {
            try await cache.sync(all: result)
        }

        let installedTask = Task {
            try await cache.sync(installed: installed.value)
        }

        let outdatedTask = Task {
            let outdated = await installed.value.filter(\.outdated)
            try await cache.sync(outdated: outdated)
        }

        _ = try await (resultTask.value, installedTask.value, outdatedTask.value)

        return result
    }

    func list(cask: Bool) async throws -> [ListResult] {
        let caskFlag = cask ? " --cask" : ""

        let result = try await executeBrew(command: "list --versions\(caskFlag)")

        return result.matches(of: listRegex).map {
            ListResult(
                name: $0.output.1.trimmingCharacters(in: .whitespacesAndNewlines),
                version: $0.output.2.trimmingCharacters(in: .whitespacesAndNewlines)
//        cask: cask
            )
        }
    }

    public func install(name: PackageIdentifier) async throws {
        let brew = try await whichBrew()
        let stream = await Process.stream(command: "\(brew) install \(name.rawValue)")

        await MainActor.run {
            self.stream?.cancel()
            streamCancellable = stream.objectWillChange.sink {
                self.objectWillChange.send()
            }
            self.stream = stream
        }
        _ = try await stream.value
        _ = try await update()
    }

    public func uninstall(name: PackageIdentifier) async throws {
        let brew = try await whichBrew()
        let stream = await Process.stream(command: "\(brew) uninstall \(name.rawValue)")
        await MainActor.run {
            self.stream?.cancel()
            streamCancellable = stream.objectWillChange.sink {
                self.objectWillChange.send()
            }
            self.stream = stream
        }
        try await stream.value
        _ = try await update()
    }

    public func upgrade(name: PackageIdentifier) async throws {
        let brew = try await whichBrew()
        let stream = await Process.stream(command: "\(brew) upgrade \(name.rawValue)")
        await MainActor.run {
            self.stream?.cancel()
            streamCancellable = stream.objectWillChange.sink {
                self.objectWillChange.send()
            }
            self.stream = stream
        }
        try await stream.value
        _ = try await update()
    }

    @SearchActor
    public func search(query: String?) async throws {
        guard let query else {
            await MainActor.run {
                queryResult = nil
            }
            return
        }

        try Task.checkCancellation()

        let queryLowerCase = query.lowercased()

//    let res = await cacheAllSorted.filter { item in
//      item.full_name.rawValue.lowercased().contains(queryLowerCase)
//    }

        try Task.checkCancellation()

        await MainActor.run {
            self.queryResult = nil
        }
    }

    public func done() async {
        await MainActor.run {
            self.stream = nil
            self.objectWillChange.send()
        }
    }
}

struct StdErr: Error {
    let message: String
    let command: String
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

// swiftlint:enable identifier_name

// actor SearchActor {
//  func run<T>(resultType _: T.Type = T.self,
//              body: @MainActor @Sendable () async throws -> T) async rethrows -> T where T: Sendable
//  {
//    try await body()
//  }
// }
//
// actor UpdateActor {
//  func run<T>(resultType _: T.Type = T.self,
//              body: @MainActor @Sendable () async throws -> T) async rethrows -> T where T: Sendable
//  {
//    try await body()
//  }
// }

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
actor UpdateActor {
    static let shared = UpdateActor()
    static func run<T>(
        resultType _: T.Type = T.self,
        body: @UpdateActor @Sendable () async throws -> T
    ) async rethrows -> T where T: Sendable {
        try await body()
    }
}
