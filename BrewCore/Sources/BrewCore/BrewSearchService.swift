//
//  BrewSearchService.swift
//
//
//  Created by Tomas Harkema on 04/09/2023.
//

import BrewShared
import Foundation
import Inject
import Processed
import SwiftTracing

@MainActor
public final class BrewSearchService: ObservableObject, LoadableSupport {
//    private let cache: BrewCache

  @Injected(\.brewService)
  private var service: BrewService

  @Injected(\.helperProcessService)
  private var processService
  
  @Injected(\.brewCache)
  private var cache

  @Published
  public var queryResult: LoadableState<[PackageCache]> = .absent

  @Published
  public var queryRemoteResult: LoadableState<[Result<PackageInfo, any Error>]> = .absent

  private let signposter = Signposter(
    subsystem: Bundle.main.bundleIdentifier!,
    category: "BrewSearchService"
  )

//    public init(cache: BrewCache, service: BrewService, processService: BrewProcessService) {
//        self.cache = cache
//        self.service = service
//        self.processService = processService
//    }

//    init() {
//        let cache = await BrewCache()
//    }
  public init() {}

  public func search(query: String?) async {
    guard let query, query.count >= 3 else {
      reset(\.queryResult)
      reset(\.queryRemoteResult)
      return
    }

    if Task.isCancelled {
      return
    }

    let queryLowerCase = query.lowercased()

    let task = load(\.queryResult, priority: .medium) {
      let result = try await self.cache.search(query: queryLowerCase)
      try Task.checkCancellation()

      self.load(\.queryRemoteResult, priority: .medium) {
        let res = try await self.searchRemote(query: query, fromCache: result)
        try Task.checkCancellation()
        return res
      }

      return result
    }

    await task.value
  }

  private nonisolated func searchRemote(
    query: String?, fromCache: [PackageCache] = []
  ) async throws -> [Result<PackageInfo, any Error>] {
    guard let query, query.count >= 3 else {
      return []
    }

    let queryLowerCase = query.lowercased()

    return try await signposter.measure(withNewId: "searchRemote") {
      let remoteResult = try await self.processService.searchFormula(query: queryLowerCase)
      try Task.checkCancellation()
      let results = try await self.fetchInfo(for: remoteResult, fromCache: fromCache)

      Task {
        try await self.storeInCache(results: results)
      }

      try Task.checkCancellation()

      return results
    }
  }

  private nonisolated func storeInCache(results: [Result<PackageInfo, any Error>]) async throws {
    try? await self.cache.sync(all: results.lazy.compactMap {
      if case let .success(.remote(remote)) = $0 {
        remote
      } else {
        nil
      }
    })
  }

  private func fetchInfo(
    for packageIdentifiers: [PackageIdentifier],
    fromCache: [PackageCache] = [],
    concurrentFetches: Int = 4
  ) async throws -> [Result<PackageInfo, any Error>] {
    try await withThrowingTaskGroup(of: [Result<PackageInfo, any Error>].self) { group in

      for (index, pkg) in packageIdentifiers.enumerated() {
        try Task.checkCancellation()

        let foundInCache = fromCache.first {
          $0.id == pkg
        }

        if let foundInCache {
          print("ALREADY FOUND", foundInCache.id)
          continue
        }

        if index % concurrentFetches == 0 {
          _ = try await group.next()
        }

        _ = group.addTaskUnlessCancelled {
          do {
            return try await measure("infoFormula") {
              if let local = try await self.fetchInfoLocal(
                for: pkg,
                maxTtl: .seconds(60 * 60 * 24)
              ) {
                return [.success(.cached(local))]
              }

              let info = try await self.processService.infoFormula(package: pkg)
              return info.map { .success(.remote($0.onlyRemote)) }
            }
          } catch {
            print(error)
            return [.failure(error)]
          }
        }
      }

      return try await group.reduce([], +)
    }
  }

  private func fetchInfoLocal(
    for packageIdentifier: PackageIdentifier,
    maxTtl: Duration
  ) async throws -> PackageCache? {
    guard let package = try? await self.cache.package(by: packageIdentifier) else {
      return nil
    }

    let (seconds, _) = maxTtl.components
    let lastUpdated = Int(abs(package.lastUpdated.timeIntervalSinceNow))

    if seconds < lastUpdated {
      return nil
    }

    return package
  }
}

public extension InjectedValues {
  var brewSearchService: BrewSearchService {
    get { Self[BrewSearchServiceKey.self] }
    set { Self[BrewSearchServiceKey.self] = newValue }
  }
}

private struct BrewSearchServiceKey: InjectionKey {
  @MainActor
  static var currentValue: BrewSearchService = .init()
}
