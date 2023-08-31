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

struct PackageIdentifier: RawRepresentable, Hashable {
  let rawValue: String
}

extension PackageIdentifier: Encodable {
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

extension PackageIdentifier: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    rawValue = try container.decode(String.self)
  }
}

extension PackageIdentifier: Identifiable {
  var id: Int {
    hashValue
  }
}

typealias InfoResultDict = [PackageIdentifier: InfoResult]

extension InfoResultDict: RawRepresentable {
  public init?(rawValue: String) {
    do {
      let res = try JSONDecoder()
        .decode([PackageIdentifier: InfoResult].self, from: rawValue.data(using: .utf8)!)
      self = res
    } catch {
      print(error)
      return nil
    }
  }

  public var rawValue: String {
    String(data: (try? JSONEncoder().encode(self))!, encoding: .utf8) ?? ""
  }
}

typealias InfoResultSort = [InfoResult]

extension InfoResultSort: RawRepresentable {
  public init?(rawValue: String) {
    do {
      let res = try JSONDecoder().decode([InfoResult].self, from: rawValue.data(using: .utf8)!)
      self = res
    } catch {
      print(error)
      return nil
    }
  }

  public var rawValue: String {
    String(data: (try? JSONEncoder().encode(self))!, encoding: .utf8) ?? ""
  }
}

class BrewService: ObservableObject {
  static let shared = BrewService()

  @MainActor @AppStorage("cacheInstalled") var cacheInstalled = InfoResultDict()
  @MainActor @AppStorage("cacheInstalledSorted") var cacheInstalledSorted = InfoResultSort()
  @MainActor @AppStorage("cacheAll") var cacheAll = InfoResultDict()
  @MainActor @AppStorage("cacheAllSorted") var cacheAllSorted = InfoResultSort()

  @MainActor @AppStorage("cacheOutdated") var cacheOutdated = InfoResultDict()
  @MainActor @AppStorage("cacheOutdatedSorted") var cacheOutdatedSorted = InfoResultSort()

  @MainActor @Published var queryResult: InfoResultSort?

  @MainActor
  private var streamCancellable: AnyCancellable?
  @MainActor @Published var stream: StreamStreamingAndTask?
  @MainActor @Published private var updateTask: Task<Void, Error>?
  @MainActor var isUpdateRunning: Bool {
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

  @MainActor
  func update() async throws {
    if let updateTask {
      return try await updateTask.value
    }
    let updateTask = Task { @UpdateActor in
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

  func fetchInfo() async throws -> [InfoResult] {
    let info = try await executeBrew(command: "info --json=v1 --eval-all")

    let result = try JSONDecoder().decode(
      [FallbackCodable<InfoResult>].self,
      from: info.data(using: .utf8)!
    )
    .compactMap(\.value)

    let installed = result.filter {
      !$0.installed.isEmpty
    }
    let outdated = installed.filter(\.outdated)

    async let cached = Dictionary(grouping: result) {
      $0.full_name
    }.mapValues {
      $0.first!
    }

    async let installedCached = Dictionary(grouping: installed) {
      $0.full_name
    }.mapValues {
      $0.first!
    }

    async let outdatedCached = Dictionary(grouping: outdated) {
      $0.full_name
    }.mapValues {
      $0.first!
    }

    let cacheInstalled = await installedCached
    let cacheAll = await cached
    let cacheOutdated = await outdatedCached

    Task { @MainActor in
      cacheInstalledSorted = installed
      self.cacheInstalled = cacheInstalled

      cacheAllSorted = result
      self.cacheAll = cacheAll

      cacheOutdatedSorted = outdated
      self.cacheOutdated = cacheOutdated
    }

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

  func install(name: PackageIdentifier) async throws {
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

  func uninstall(name: PackageIdentifier) async throws {
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

  func upgrade(name: PackageIdentifier) async throws {
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
  func search(query: String?) async throws {
    guard let query else {
      await MainActor.run {
        queryResult = nil
      }
      return
    }

    try Task.checkCancellation()

    let queryLowerCase = query.lowercased()

    let res = await cacheAllSorted.filter { item in
      item.full_name.rawValue.lowercased().contains(queryLowerCase)
    }

    try Task.checkCancellation()

    await MainActor.run {
      self.queryResult = res
    }
  }

  func done() async {
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

struct ListResult: Hashable {
  let name: String
  let version: String
  //  let cask: Bool
}

struct InfoResult: Codable, Hashable {
  let name: String
  let full_name: PackageIdentifier
  let tap: String
  let desc: String?
  let license: String?
  let homepage: String
  let installed: [InstalledVersion]
  let versions: Versions

  let pinned: Bool
  let outdated: Bool
  let deprecated: Bool
  let deprecation_date: String?
  let deprecation_reason: String?
  let disabled: Bool
  let disable_date: String?
  let disable_reason: String?
  //  let service: String?
}

struct InstalledVersion: Codable, Hashable {
  let version: String
  let installed_as_dependency: Bool
}

struct Versions: Codable, Hashable {
  let stable: String?
  let head: String?
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
enum SearchActor {
  actor ActorType {}

  static let shared: ActorType = .init()

  static func run<T>(
    resultType _: T.Type = T.self,
    body: @SearchActor @Sendable () async throws -> T
  ) async rethrows -> T where T: Sendable {
    try await body()
  }
}

@globalActor
enum UpdateActor {
  actor ActorType {}

  static let shared: ActorType = .init()

  static func run<T>(
    resultType _: T.Type = T.self,
    body: @UpdateActor @Sendable () async throws -> T
  ) async rethrows -> T where T: Sendable {
    try await body()
  }
}
