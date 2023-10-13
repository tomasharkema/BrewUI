//
//  BrewHelperProcessService.swift
//
//
//  Created by Tomas Harkema on 07/10/2023.
//

import BrewHelperXPC
import BrewShared
import Foundation
import Inject
import OSLog

public final class BrewHelperProcessService: BrewProcessServiceProtocol, ObservableObject {
  private let logger = Logger(subsystem: "a", category: "b")
  private let connection: BrewProtocolServiceXPCConnection
  private let proxy: any BrewProtocolService

  init() {
    let connection =
      BrewProtocolServiceXPCConnection(xpc: .service("io.harkema.BrewUIXPCService"))
    connection.resume()
    self.connection = connection

    let proxy = connection.remoteObjectProxy { error in
      print(error)
    }
    self.proxy = proxy
  }

  public func shell(command: BrewCommand) async throws -> CommandOutput {
    try await proxy.shell(command: command)
  }

  public func infoFromBrew(command: BrewCommand.InfoCommand) async throws -> [InfoResponse] {
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

  public func stream(
    command _: BrewCommand
  ) async throws -> StreamStreamingAndTask {
    fatalError()
//        return await Process.stream(logger: logger, command: command)
  }

  public func infoFormula(package: PackageIdentifier) async throws -> [InfoResponse] {
    try await infoFromBrew(command: .formula(package))
  }

  public func update() async throws -> UpdateResult {
    let res = try await shell(command: .update)
    return try .init(res)
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

public extension InjectedValues {
  var helperProcessService: any BrewProcessServiceProtocol {
    get { Self[BrewHelperProcessServiceKey.self] }
    set { Self[BrewHelperProcessServiceKey.self] = newValue }
  }
}

private struct BrewHelperProcessServiceKey: InjectionKey {
  static var currentValue: any BrewProcessServiceProtocol = BrewHelperProcessService()
}
