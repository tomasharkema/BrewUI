//
//  BrewStreaming.swift
//
//
//  Created by Tomas Harkema on 05/09/2023.
//

import BrewShared
import Combine
import Foundation
import SwiftTracing

@MainActor
public final class BrewStreaming: ObservableObject, Identifiable {
    private let service: BrewService
    private let process: BrewProcessService

    public let id = UUID()

    private var streamCancellable: AnyCancellable?
    @Published public var stream: StreamStreamingAndTask

    init(service: BrewService, process: BrewProcessService, stream: StreamStreamingAndTask) {
        self.service = service
        self.process = process
        self.stream = stream

        streamCancellable = stream.objectWillChange.sink {
            self.objectWillChange.send()
        }

        #if DEBUG
//            _printChanges()
        #endif
    }

    static func install(
        service: BrewService, process: BrewProcessService, name: PackageIdentifier
    ) async throws -> BrewStreaming {
        let stream = try await process.stream(command: .install(name))

        return BrewStreaming(service: service, process: process, stream: stream)
    }

    static func uninstall(
        service: BrewService, process: BrewProcessService, name: PackageIdentifier
    ) async throws -> BrewStreaming {
        let stream = try await process.stream(command: .uninstall(name))

        return BrewStreaming(service: service, process: process, stream: stream)
    }

    static func upgrade(
        service: BrewService, process: BrewProcessService, name: PackageIdentifier
    ) async throws -> BrewStreaming {
        let stream = try await process.stream(command: .upgrade(.package(name)))

        return BrewStreaming(service: service, process: process, stream: stream)
    }

    static func upgrade(
        service: BrewService, process: BrewProcessService
    ) async throws -> BrewStreaming {
        let stream = try await process.stream(command: .upgrade(.all))

        return BrewStreaming(service: service, process: process, stream: stream)
    }

//    public func done() async {
//        await MainActor.run {
//            self.stream = nil
//            self.objectWillChange.send()
//        }
//    }
}
