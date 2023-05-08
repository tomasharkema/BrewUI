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

  func shell(command: String) async throws -> String {
    let task = Task {
      print("EXECUTE: \(command)")

      let task = Process()
      let pipe = Pipe()
      let pipeErr = Pipe()

      let userShell = ProcessInfo.processInfo.environment["SHELL"]

      task.standardOutput = pipe
      task.standardError = pipeErr
      task.arguments = ["-l", "-c", command]
      task.launchPath = userShell
      task.standardInput = nil
      task.launch()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8)! // .asciiString
      let outputErr = String(data: dataErr, encoding: .utf8)! // .asciiString

      task.waitUntilExit()

      if task.terminationStatus == 0 {
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
      }

      throw StdErr(message: (output + "\n" + outputErr)
        .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    return try await task.value
  }

  @MainActor private var appendedData = Data()
  @MainActor @Published var stream: StreamOutput?

  func stream(command: String) async throws {
    try await Task {
      if await stream != nil {
        throw NSError(domain: "isStreaming", code: 69)
      }
      await MainActor.run {
        stream = StreamOutput(stream: "", isStreamingDone: false)
      }
      defer {
        Task {
          await MainActor.run {
            stream?.isStreamingDone = true
          }
        }
      }

      print("EXECUTE: \(command)")
      await MainActor.run {
        self.stream?.stream += "EXECUTE: \(command)\n"
      }

      let task = Process()
      let pipe = Pipe()
      let pipeErr = Pipe()

      let userShell = ProcessInfo.processInfo.environment["SHELL"]

      task.standardOutput = pipe
      task.standardError = pipeErr
      task.arguments = ["-l", "-c", command]
      task.launchPath = userShell
      task.standardInput = nil
      task.launch()

      pipe.fileHandleForReading.readabilityHandler = { handle in

        let newData: Data = handle.availableData
        Task {
          if newData.count == 0 {
            handle.readabilityHandler = nil // end of data signal is an empty data object.
          } else {
            await MainActor.run { [self] in
              stream?.stream += String(data: newData, encoding: .utf8) ?? ""
            }
          }
        }
      }

      pipeErr.fileHandleForReading.readabilityHandler = { handle in

        let newData: Data = handle.availableData
        Task {
          if newData.count == 0 {
            handle.readabilityHandler = nil // end of data signal is an empty data object.
          } else {
            await MainActor.run { [self] in
              if let s = String(data: newData, encoding: .utf8) {
                stream?.stream += "ERR: \(s)"
              }
            }
          }
        }
      }

      task.waitUntilExit()

      if task.terminationStatus != EXIT_SUCCESS {
        await MainActor.run { [self] in
          stream?.stream += "CODE: \(task.terminationStatus)"
        }

        throw NSError(domain: "EXIT_NOT_SUCCESS", code: Int(task.terminationStatus))
      }

    }.value
  }

  func whichBrew() async throws -> String {
    let result = try await (shell(command: "which brew"))
      .trimmingCharacters(in: .whitespacesAndNewlines)
    print("FOUND BREW: \(result)")
    return result
  }

  func executeBrew(command: String) async throws -> String {
    let brew = try await whichBrew()
    return try await shell(command: "\(brew) \(command)")
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
    try await stream(command: "\(brew) install \(name)")
    _ = try await updateAll()
  }

  func uninstall(name: String) async throws {
    let brew = try await whichBrew()
    try await stream(command: "\(brew) uninstall \(name)")
    _ = try await updateAll()
  }

  func upgrade(name: String) async throws {
    let brew = try await whichBrew()
    try await stream(command: "\(brew) upgrade \(name)")
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
