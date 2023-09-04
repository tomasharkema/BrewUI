//
//  BrewSearchService.swift
//
//
//  Created by Tomas Harkema on 04/09/2023.
//

import Foundation

@MainActor
public final class BrewSearchService: ObservableObject {
    private let cache: BrewCache
    private let service: BrewService

    private var searchTask: Task<[PackageCache], Error>?
    private var searchRemoteTask: Task<Void, Error>?

    @Published public var queryResult: [PackageCache]?
    @Published public var queryRemoteResult: [Result<PackageInfo, Error>]?

    public init(cache: BrewCache, service: BrewService) {
        self.cache = cache
        self.service = service
    }

    public func search(query: String?) async throws {
        guard let query, query.count >= 3 else {
            queryResult = nil
            return
        }

        try Task.checkCancellation()

        let queryLowerCase = query.lowercased()


        searchTask?.cancel()
        let task = Task {
            let localResult = try await cache.search(query: queryLowerCase)

            try Task.checkCancellation()

            self.queryResult = localResult
            return localResult
        }
        searchTask = task

        searchRemote(query: query)

        _ = try await task.value
    }

    private func searchRemote(query: String?) {
        let concurrentFetches = 8
        guard let query, query.count >= 3 else {
            queryRemoteResult = nil
            return
        }

        let queryLowerCase = query.lowercased()

        searchRemoteTask?.cancel()

        queryRemoteResult = nil

        let task = Task {
            try Task.checkCancellation()
            let brew = try await self.service.whichBrew()

            let remoteResult = try await self.service.searchFormula(query: queryLowerCase)

            let localResult = try await searchTask?.value

            let results = try await withThrowingTaskGroup(of: [Result<PackageInfo, Error>].self) { group in

                for (index, pkg) in remoteResult.enumerated() {
                    try Task.checkCancellation()

                    let localCandidate = localResult?.first { $0.id == pkg }

                    if index % concurrentFetches == 0 {
                        _ = try await group.next()
                    }

                    guard localCandidate == nil else { continue }

                    _ = group.addTaskUnlessCancelled {
                        do {
                            let info = try await self.service.infoFormula(package: pkg, brewOverride: brew)
                            return info.map { .success(.remote($0)) }
                        } catch {
                            print(error)
                            return [.failure(error)]
                        }
                    }
                }

                return try await group.reduce([], +)
            }

            Task {
                try await self.cache.sync(all: results.compactMap {
                    if case .success(.remote(let r)) = $0 {
                        return r
                    } else {
                        return nil
                    }
                })
            }

            try Task.checkCancellation()
            queryRemoteResult = results
        }
        searchRemoteTask = task
    }
}
