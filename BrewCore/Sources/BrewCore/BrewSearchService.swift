//
//  BrewSearchService.swift
//
//
//  Created by Tomas Harkema on 04/09/2023.
//

import BrewShared
import Foundation
import Processed
import SwiftTracing

@MainActor
public final class BrewSearchService: ObservableObject, LoadableSupport {
    private let cache: BrewCache
    private let service: BrewService
    private let processService: BrewProcessService

    @Published
    public var queryResult: LoadableState<[PackageCache]> = .absent

    @Published
    public var queryRemoteResult: LoadableState<[Result<PackageInfo, any Error>]> = .absent

    private let signposter = Signposter(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "BrewSearchService"
    )

    public init(cache: BrewCache, service: BrewService, processService: BrewProcessService) {
        self.cache = cache
        self.service = service
        self.processService = processService
    }

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

            let task = self.load(\.queryRemoteResult, priority: .medium) {
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
                await self.storeInCache(results: results)
            }

            try Task.checkCancellation()

            return results
        }
    }

    private nonisolated func storeInCache(results: [Result<PackageInfo, any Error>]) async {
        try? await cache.sync(all: results.compactMap {
            if case let .success(.remote(remote)) = $0 {
                return remote
            } else {
                return nil
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
                            if let local = await self.fetchInfoLocal(
                                for: pkg,
                                maxTtl: .seconds(60 * 60 * 24)
                            ) {
                                return [.success(.cached(local))]
                            }

                            let info = try await self.processService.infoFormula(package: pkg)
                            return info.map { .success(.remote($0)) }
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
    ) async -> PackageCache? {
        guard let package = try? await cache.package(by: packageIdentifier) else {
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
