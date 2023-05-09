//
//  BrewService.swift
//  BrewUI
//
//  Created by Tomas Harkema on 05/05/2023.
//

// swiftlint:disable identifier_name

import Foundation
import SwiftUI

typealias InfoResultDict = [String: InfoResult]

extension InfoResultDict: RawRepresentable {
  public init?(rawValue: String) {
    do {
      let res = try JSONDecoder()
        .decode([String: InfoResult].self, from: rawValue.data(using: .utf8)!)
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

  private let listRegex = /(.+) (.+)/

  private init() {}

//  @MainActor private var appendedData = Data()
  @Published var stream: StreamStreaming?

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

  func info(installed: Bool) async throws -> [InfoResult] {
    let arg = installed ? " --installed" : " --eval-all"
    if installed {
      try await executeBrew(command: "update")
    }

    let info = try await executeBrew(command: "info --json=v1\(arg)")

    let result = try JSONDecoder().decode([InfoResult].self, from: info.data(using: .utf8)!)

    let cached = Dictionary(grouping: result) {
      $0.name
    }.mapValues {
      $0.first!
    }

    if installed {
      await MainActor.run {
        cacheInstalledSorted = result
        cacheInstalled = cached
      }
    } else {
      await MainActor.run {
        cacheAllSorted = result
        cacheAll = cached
      }
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

  // func listInstalledItems() async throws -> [ListResult] {

  func listInstalledItems() async throws -> [InfoResult] {
    async let info = info(installed: true)

//    async let resultCask = list(cask: false)
//    async let result = list(cask: true)

//    let combined = Set([
//      try await resultCask,
    ////      try await result,
//    ].joined()).sorted {
//      $0.name < $1.name
//    }

    return try await info
  }

  func listAllItems() async throws -> [InfoResult] {
    try await info(installed: false)
  }

  func outdated() async throws -> [InfoResult] {
    try await listInstalledItems().filter(\.outdated)
  }

  func install(name: String) async throws {
    let brew = try await whichBrew()
    await MainActor.run {
      stream = Process.stream(command: "\(brew) install \(name)")
    }
    _ = try await updateAll()
  }

  func uninstall(name: String) async throws {
    let brew = try await whichBrew()
    await MainActor.run {
      stream = Process.stream(command: "\(brew) uninstall \(name)")
    }
    _ = try await updateAll()
  }

  func upgrade(name: String) async throws {
    let brew = try await whichBrew()
    await MainActor.run {
      stream = Process.stream(command: "\(brew) upgrade \(name)")
    }
    _ = try await updateAll()
  }

  func updateAll() async throws {
    async let a = listAllItems()
    async let b = listInstalledItems()
    async let c = outdated()

    try await a
    try await b
    try await c
  }

  func done() {
    Task {
      await MainActor.run {
        self.stream = nil
      }
    }
  }
}

struct StdErr: Error {
  let message: String
}

extension String {
  var asciiString: String {
    String(unicodeScalars.filter(\.isASCII))
  }
}

struct ListResult: Hashable {
  let name: String
  let version: String
  //  let cask: Bool
}

struct InfoResult: Codable, Hashable {
  let name: String
  let full_name: String
  let tap: String
  let desc: String
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
