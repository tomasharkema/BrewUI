//
//  BrewUpdateService.swift
//  
//
//  Created by Tomas Harkema on 01/10/2023.
//

import Foundation
import OSLog
import BrewHelpers
import Processed
import SwiftUI
import BrewShared

public final class BrewUpdateService: ObservableObject, LoadableSupport {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BrewUpdateService")

    private let service: BrewService
    private let processService: BrewProcessService

    @MainActor @Published
    public private(set) var updating: LoadableState<Bool> = .absent

    @MainActor @Published
    public private(set) var upgrading: LoadableState<Bool> = .absent

    @MainActor @Published
    public private(set) var installing: LoadableState<Bool> = .absent

    @MainActor @Published
    public private(set) var uninstalling: LoadableState<Bool> = .absent

    @MainActor @Published
    public private(set) var stream: BrewStreaming?

    public init(service: BrewService, processService: BrewProcessService) {
        self.service = service
        self.processService = processService
    }

    @MainActor
    public func update() async {
        let task = load(\.updating, priority: .medium) { yield in
            let res = try await self.processService.update()
            self.logger.info("UPDATE DONE! \(String(describing: res)), fetching info...")
            yield(.loaded(true))
            _ = try await self.service.fetchInfo()
            self.logger.info("UPDATE DONE!")
            yield(.loaded(false))
        }

        await task.value
    }

    @MainActor
    public func upgradeAll() async throws {
        let stream = try await self.service.upgrade()
        self.stream = stream

        load(\.upgrading, priority: .medium) { yield in
            // wait for streaming result
            try await stream.stream.task.value
            yield(.loaded(true))
            _ = try await self.service.fetchInfo()
            yield(.loaded(false))
        }
    }

    @MainActor
    public func upgrade(name: PackageIdentifier) async throws {
        let stream = try await self.service.upgrade(name: name)
        self.stream = stream

        load(\.upgrading, priority: .medium) { yield in
            // wait for streaming result
            try await stream.stream.task.value
            yield(.loaded(true))
            _ = try await self.service.fetchInfo()
            yield(.loaded(false))
        }
    }

    @MainActor
    public func install(name: PackageIdentifier) async throws {
        let stream = try await self.service.install(name: name)
        self.stream = stream

        load(\.installing, priority: .medium) { yield in
            // wait for streaming result
            try await stream.stream.task.value
            yield(.loaded(true))
            _ = try await self.service.fetchInfo()
            yield(.loaded(false))
        }
    }

    @MainActor
    public func uninstall(name: PackageIdentifier) async throws {
        let stream = try await self.service.uninstall(name: name)
        self.stream = stream

        load(\.uninstalling, priority: .medium) { yield in
            // wait for streaming result
            try await stream.stream.task.value
            yield(.loaded(true))
            _ = try await self.service.fetchInfo()
            yield(.loaded(false))
        }
    }

    @MainActor
    public var isAnyLoading: Bool {
        updating.isLoading || upgrading.isLoading || installing.isLoading || uninstalling.isLoading
    }
}
