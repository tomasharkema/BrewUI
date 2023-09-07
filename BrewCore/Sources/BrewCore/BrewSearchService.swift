//
//  BrewSearchService.swift
//
//
//  Created by Tomas Harkema on 04/09/2023.
//

import Foundation
import BrewShared

@MainActor
public final class BrewSearchService: ObservableObject {
    private let cache: BrewCache
    private let service: BrewService

    private var searchTask: Task<[PackageCache], Error>?
    private var searchRemoteTask: Task<Void, Error>?

    @Published public var queryResult: LoadingState<[PackageCache]> = .idle
    @Published public var queryRemoteResult: LoadingState<[Result<PackageInfo, Error>]> = .idle

    public init(cache: BrewCache, service: BrewService) {
        self.cache = cache
        self.service = service
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
        let concurrentFetches = 8
        guard let query, query.count >= 3 else {
            queryRemoteResult = .idle
            return
        }

        let queryLowerCase = query.lowercased()

        searchRemoteTask?.cancel()

        queryRemoteResult = .loading

        let task = Task.detached {
            try Task.checkCancellation()

            let remoteResult = try await self.service.searchFormula(query: queryLowerCase)

            let localResult = try await self.searchTask?.value

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
                            let info = try await self.service.infoFormula(package: pkg)
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
        searchRemoteTask = task
    }
}
