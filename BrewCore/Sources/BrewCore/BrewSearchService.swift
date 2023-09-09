//
//  BrewSearchService.swift
//
//
//  Created by Tomas Harkema on 04/09/2023.
//

import Foundation
import BrewShared
import SwiftTracing

@MainActor
public final class BrewSearchService: ObservableObject {
    private let cache: BrewCache
    private let service: BrewService
    private let process: BrewProcessService

    private var searchTask: Task<[PackageCache], any Error>?
    private var searchRemoteTask: Task<Void, any Error>?

    @Published public var queryResult: LoadingState<[PackageCache]> = .idle
    @Published public var queryRemoteResult: LoadingState<[Result<PackageInfo, any Error>]> = .idle

    private let signposter = Signposter(subsystem: Bundle.main.bundleIdentifier!, category: "BrewSearchService")

    public init(cache: BrewCache, service: BrewService, process: BrewProcessService) {
        self.cache = cache
        self.service = service
        self.process = process
    }

    public func search(query: String?) async throws {
        guard let query, query.count >= 3 else {
            searchTask?.cancel()
            queryResult = .idle
            return
        }

        try Task.checkCancellation()

        let queryLowerCase = query.lowercased()

        self.queryResult = .loading

        searchTask?.cancel()
        let task = Task.detached {
            let localResult = try await self.cache.search(query: queryLowerCase)

            try Task.checkCancellation()

            Task { @MainActor in
                self.queryResult = .result(localResult)
            }

            return localResult
        }
        searchTask = task

        searchRemote(query: query)

        _ = try await task.value
    }

    private func searchRemote(query: String?) {
        guard let query, query.count >= 3 else {
            queryRemoteResult = .idle
            return
        }

        let queryLowerCase = query.lowercased()

        searchRemoteTask?.cancel()

        queryRemoteResult = .loading

        let task = Task.detached {
            try Task.checkCancellation()

            try await self.signposter.measure(withNewId: "searchRemote") {

                let remoteResult = try await self.process.searchFormula(query: queryLowerCase)
                let results = try await self.fetchInfo(for: remoteResult)

                Task {
                    try await self.cache.sync(all: results.compactMap {
                        if case .success(.remote(let remote)) = $0 {
                            return remote
                        } else {
                            return nil
                        }
                    })
                }

                try Task.checkCancellation()
                Task { @MainActor in
                    self.queryRemoteResult = .result(results)
                }
            }
        }
        searchRemoteTask = task
    }

    private func fetchInfo(
        for packageIdentifiers: [PackageIdentifier], concurrentFetches: Int = 4
    ) async throws -> [Result<PackageInfo, any Error>] {
        try await withThrowingTaskGroup(of: [Result<PackageInfo, any Error>].self) { group in

            for (index, pkg) in packageIdentifiers.enumerated() {
                try Task.checkCancellation()

                if index % concurrentFetches == 0 {
                    _ = try await group.next()
                }

//                guard localCandidate == nil else { continue }

                _ = group.addTaskUnlessCancelled {
                    do {
                        return try await measure("infoFormula") {

                            if let local = await self.fetchInfoLocal(for: pkg, maxTtl: .seconds(60 * 60 * 24)) {
                                return [.success(.cached(local))]
                            }

                            let info = try await self.process.infoFormula(package: pkg)
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
