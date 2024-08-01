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
import Injected
import OSLog
import RawJson

public final class BrewService: ObservableObject, Sendable {
//    @Injected(\.brewCache)
//    private var cache: BrewCache

  @Injected(\.brewApi)
  private var api
  
  @Injected(\.brewShippedFileKey)
  private var localFile

  @Injected(\.helperProcessService)
  private var processService

  @Injected(\.brewCache)
  private var cache

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BrewService")

//    public init(cache: BrewCache, api: BrewApi, processService: BrewProcessService) {
//        self.cache = cache
//        self.api = api
//        self.processService = processService
//    }

  public init() {}

  public func fetchInfo() async throws {
    try await EnsureOnce.once {

      try await self.initialSyncIfNeeded()

      let formulaResult = try await self.api.formula()
      let formula = formulaResult.lazy.compactMap(\.value)
      try await self.cache.sync(all: formula)

      let installedTask = Task {
        return try await self.processService.infoFormulaInstalled()
      }

      let installedSyncTask = Task {
        try await self.cache.sync(installed: installedTask.value)
      }

//      let outdatedTask = Task {
//        let outdated = try await installedTask.value.filter(\.outdated)
//        try await cache.sync(outdated: outdated)
//      }

      let tapInfosTask = Task {
        let taps = try await self.processService.taps()
        let tapsInfos = try await self.fetchTapInfos(taps: taps)
        try await self.cache.sync(taps: tapsInfos)
        print(tapsInfos)
        return tapsInfos
      }

      let date = Date()

      //            async let list = self.listFormula()

      _ = try await (
        installedTask.value, installedSyncTask.value,
//        outdatedTask.value, 
        tapInfosTask.value
      )
      //            print(listthing)
      self.logger.info("timetaken \(abs(date.timeIntervalSinceNow))")
//            return res
    }
  }

  public nonisolated func initialSyncIfNeeded() async {
    do {
      try await self.loadLocalFile(cache: cache)
    } catch {
      print(error)
    }
  }

  private func loadLocalFile(cache: BrewCache) async throws {
    async let shippedUpdatedAsync = self.localFile.localFormulaUpdate()
    async let localUpdatedAsync = cache.lastUpdated()

    let shippedUpdated = try await shippedUpdatedAsync
    let localUpdated = try await localUpdatedAsync

    print(shippedUpdated, localUpdated)

    if let localUpdated {
      if shippedUpdated.updatedHashValue == localUpdated.updatedHashValue {
        return
      }
      if shippedUpdated.updatedDate > localUpdated.updatedDate {
        return
      }
    }
    
    let local = try await self.localFile.localFormula()
    let elements = local.lazy.compactMap(\.value)
    try await cache.sync(all: elements)
    try await cache.updateLastUpdated(local: shippedUpdated)
    await Task.yield()
  }

  private func fetchTapInfos(
    taps: [String],
    concurrentFetches: Int = 4
  ) async throws -> [TapInfo] {
    return try await withThrowingTaskGroup(of: [TapInfo].self) { group in

      let taps = taps.filter {
        $0 != PackageIdentifier.core
      }

      for (index, tap) in taps.enumerated() {
        if index % concurrentFetches == 0 {
          _ = try await group.next()
        }

        group.addTask {
          try await self.processService.tap(name: tap)
        }
      }

      return try await group.reduce(into: []) {
        $0.append(contentsOf: $1)
      }
    }
  }

  nonisolated func install(
    service _: any BrewProcessServiceProtocol,
    name: PackageIdentifier
  ) async throws -> BrewStreaming {
    try await BrewStreaming.install(processService: processService, name: name)
  }

  nonisolated func uninstall(
    service _: any BrewProcessServiceProtocol,
    name: PackageIdentifier
  ) async throws -> BrewStreaming {
    try await BrewStreaming.uninstall(processService: processService, name: name)
  }

  nonisolated func upgrade(
    service _: any BrewProcessServiceProtocol,
    name: PackageIdentifier
  ) async throws -> BrewStreaming {
    try await BrewStreaming.upgrade(processService: processService, name: name)
  }

  nonisolated func upgrade(
    service _: any BrewProcessServiceProtocol
  ) async throws -> BrewStreaming {
    try await BrewStreaming.upgrade(processService: processService)
  }

  public nonisolated func searchFormula(query: String) async throws -> [PackageIdentifier] {
    try await processService.searchFormula(query: query)
  }

  nonisolated func infoFormula(package: PackageIdentifier) async throws -> [InfoResponse] {
    try await processService.infoFormula(package: package)
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

public extension InjectedValues {
  var brewService: BrewService {
    get { Self[BrewServiceKey.self] }
    set { Self[BrewServiceKey.self] = newValue }
  }
}

private struct BrewServiceKey: InjectionKey {
  static var currentValue: BrewService? = .init()
}
