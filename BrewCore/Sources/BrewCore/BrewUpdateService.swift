//
//  BrewUpdateService.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import BrewHelpers
import BrewShared
import Foundation
import OSLog
import Processed
import SwiftUI

public enum PackageState {
    case executed
    case updated
}

public enum UpdateState {
    case updated(UpdateResult)
    case synced
}

public final class BrewUpdateService: ObservableObject, LoadableSupport {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "BrewUpdateService"
    )

    private let service: BrewService
    private let processService: BrewProcessService

    @MainActor @Published
    public private(set) var updatingAll: LoadableState<Void> = .absent

    @MainActor @Published
    public private(set) var updating: LoadableState<UpdateState> = .absent

    @MainActor @Published
    public private(set) var upgrading: LoadableState<PackageState> = .absent

    @MainActor @Published
    public private(set) var installing: LoadableState<PackageState> = .absent

    @MainActor @Published
    public private(set) var uninstalling: LoadableState<PackageState> = .absent

    @MainActor @Published
    public private(set) var stream: BrewStreaming?

    public init(service: BrewService, processService: BrewProcessService) {
        self.service = service
        self.processService = processService
    }

    @MainActor
    public func update() async {
        let task = load(\.updatingAll, priority: .medium) {
            print("updatingAll", "START!")

            let taskInner = self.load(\.updating, priority: .medium) { yield in
                let res = try await self.processService.update()
                self.logger.info("UPDATE DONE! \(String(describing: res)), fetching info...")
                yield(.loaded(.updated(res)))
                try await Task.sleep(for: .seconds(10))
                _ = try await self.service.fetchInfo()
                self.logger.info("UPDATE DONE!")
                yield(.loaded(.synced))
            }
            await taskInner.value

            print("updatingAll", "DONE!")
        }

        await task.value
    }

    @MainActor
    public func upgradeAll() async throws {
        let stream = try await service.upgrade()
        self.stream = stream

        load(\.upgrading, priority: .medium) { yield in
            // wait for streaming result
            try await stream.stream.task.value
            yield(.loaded(.executed))
            _ = await self.update()
            yield(.loaded(.updated))
        }
    }

    @MainActor
    public func upgrade(name: PackageIdentifier) async throws {
        let stream = try await service.upgrade(name: name)
        self.stream = stream

        load(\.upgrading, priority: .medium) { yield in
            // wait for streaming result
            try await stream.stream.task.value
            yield(.loaded(.executed))
            _ = await self.update()
            yield(.loaded(.updated))
        }
    }

    @MainActor
    public func install(name: PackageIdentifier) async throws {
        let stream = try await service.install(name: name)
        self.stream = stream

        load(\.installing, priority: .medium) { yield in
            // wait for streaming result
            try await stream.stream.task.value
            yield(.loaded(.executed))
            _ = await self.update()
            yield(.loaded(.updated))
        }
    }

    @MainActor
    public func uninstall(name: PackageIdentifier) async throws {
        let stream = try await service.uninstall(name: name)
        self.stream = stream

        load(\.uninstalling, priority: .medium) { yield in
            // wait for streaming result
            try await stream.stream.task.value
            yield(.loaded(.executed))
            _ = await self.update()
            yield(.loaded(.updated))
        }
    }

    @MainActor
    public var isAnyLoading: Bool {
        updating.isLoading || upgrading.isLoading || installing.isLoading || uninstalling.isLoading
    }

    @MainActor
    public func streamIsDone() {
        stream = nil
    }
}

public extension UpdateState {
    var isDone: Bool {
        switch self {
        case .updated:
            false
        case .synced:
            true
        }
    }
}

public extension LoadableState<UpdateState> {
    var isDone: Bool {
        switch self {
        case let .loaded(state):
            state.isDone

        default:
            false
        }
    }
}
