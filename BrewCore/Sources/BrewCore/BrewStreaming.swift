//
//  BrewStreaming.swift
//
//
//  Created by Tomas Harkema on 05/09/2023.
//

import BrewShared
import Combine
import Foundation
import Inject

@MainActor
public final class BrewStreaming: ObservableObject, Identifiable {

    @Injected(\.brewService)
    private var service: BrewService
    @Injected(\.brewProcessService)
    private var processService: BrewProcessService

    public let id = UUID()

    private var streamCancellable: AnyCancellable?
    @Published public var stream: StreamStreamingAndTask

    init(stream: StreamStreamingAndTask) {
        self.stream = stream

        streamCancellable = stream.objectWillChange.sink {
            self.objectWillChange.send()
        }
    }

    static func install(
        processService: BrewProcessService,
        name: PackageIdentifier
    ) async throws -> BrewStreaming {
        let stream = try await processService.stream(command: .install(name))

        return BrewStreaming(stream: stream)
    }

    static func uninstall(
        processService: BrewProcessService,
        name: PackageIdentifier
    ) async throws -> BrewStreaming {
        let stream = try await processService.stream(command: .uninstall(name))

        return BrewStreaming(stream: stream)
    }

    static func upgrade(
        processService: BrewProcessService,
        name: PackageIdentifier
    ) async throws -> BrewStreaming {
        let stream = try await processService.stream(command: .upgrade(.package(name)))

        return BrewStreaming(stream: stream)
    }

    static func upgrade(
        processService: BrewProcessService
    ) async throws -> BrewStreaming {
        let stream = try await processService.stream(command: .upgrade(.all))

        return BrewStreaming(stream: stream)
    }

//    public func done() async {
//        await MainActor.run {
//            self.stream = nil
//            self.objectWillChange.send()
//        }
//    }
}
