//
//  BrewProcess.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import BrewCore
import BrewShared
import Foundation
import OSLog

struct Brew: RawRepresentable {
  let rawValue: String
}

public final class BrewProcessService: BrewProcessServiceProtocol {
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: "BrewProcessService"
  )

  public init() {}

  private var brewCached: Brew?

  private func whichBrew() async throws -> Brew {
    if let brewCached {
      return brewCached
    }

    let command = try await Process.shell(logger: logger, command: "which brew")
    let result = command.outString
    if !result.contains("brew") {
      throw NSError(domain: "brew not found", code: 42)
    }
    brewCached = Brew(rawValue: result)
    return Brew(rawValue: result)
  }

  public func stream(
    command: BrewCommand
  ) async throws -> StreamStreamingAndTask {
    let brew: Brew = try await whichBrew()
    return await Process.stream(logger: logger, command: "\(brew.rawValue) \(command.command)")
  }

  func shellStreaming(
    brew brewOverride: Brew? = nil,
    command: BrewCommand
  ) async throws -> CommandOutput {
    let brew: Brew = if let brewOverride {
      brewOverride
    } else {
      try await whichBrew()
    }
    return try await Process.shellStreaming(
      logger: logger,
      command: "\(brew.rawValue) \(command.command)"
    )
  }

  func shell(
    brew brewOverride: Brew? = nil,
    command: BrewCommand
  ) async throws -> CommandOutput {
    let brew: Brew = if let brewOverride {
      brewOverride
    } else {
      try await whichBrew()
    }
    return try await Process.shell(
      logger: logger,
      command: "\(brew.rawValue) \(command.command)"
    )
  }

  public func infoFromBrew(
    command: BrewCommand.InfoCommand
  ) async throws -> [InfoResponse] {
    do {
      let stream = try await shell(command: .info(command))
      try Task.checkCancellation()

      guard let data = stream.outString.data(using: .utf8) else {
        throw NSError(domain: "data error", code: 0)
      }
      return try JSONDecoder().decode([InfoResponse].self, from: data)
    } catch {
      logger.error("Error: \(error)")
      throw error
    }
  }

  public func infoFormulaInstalled() async throws -> [InfoResponse] {
    try await infoFromBrew(command: .installed)
  }

  public func infoFormula(package: PackageIdentifier) async throws -> [InfoResponse] {
    try await infoFromBrew(command: .formula(package))
  }

  public func update() async throws -> UpdateResult {
    let res = try await shell(command: .update)
    return try UpdateResult(res)
  }

  public func searchFormula(query: String) async throws -> [PackageIdentifier] {
    do {
      logger.info("Search for \(query)")
      let stream = try await shell(command: .search(query))
      try Task.checkCancellation()
      return try stream.outString.split(separator: "\n")
        .compactMap {
          try PackageIdentifier(raw: String($0))
        }

    } catch {
      if error is CancellationError {
        logger.info("Search for \(query) cancelled")
      }
      throw error
    }
  }

  public func taps() async throws -> [String] {
    let stream = try await shell(command: .tap)
    try Task.checkCancellation()
    return stream.outString.split(separator: "\n").map { String($0) }
  }

  public func tap(name: String) async throws -> [TapInfo] {
    do {
      let stream = try await shell(command: .tapInfo(name))
      try Task.checkCancellation()
      guard let data = stream.outString.data(using: .utf8) else {
        throw NSError(domain: "data error", code: 0)
      }
      return try JSONDecoder().decode([TapInfo].self, from: data)
    } catch {
      print(error)
      throw error
    }
  }

  static func parseListVersions(input: String) -> [ListResult] {
    let matches = input.matches(of: /(\S+) (\S+)/)
    return matches.map {
      ListResult(name: String($0.output.1), version: String($0.output.2))
    }
  }

  public func listFormula() async throws -> [ListResult] {
    let listResult = try await shell(command: .list(.versions))
    return Self.parseListVersions(input: listResult.outString)
  }
}
