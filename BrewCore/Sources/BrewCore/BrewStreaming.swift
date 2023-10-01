//
//  BrewStreaming.swift
//
//
//  Created by Tomas Harkema on 05/09/2023.
//

import BrewShared
import Combine
import Foundation

@MainActor
public final class BrewStreaming: ObservableObject, Identifiable {
    private let service: BrewService
    private let processService: BrewProcessService

    public let id = UUID()

    private var streamCancellable: AnyCancellable?
    @Published public var stream: StreamStreamingAndTask

    init(service: BrewService, processService: BrewProcessService, stream: StreamStreamingAndTask) {
        self.service = service
        self.processService = processService
        self.stream = stream

//        streamCancellable = stream.objectWillChange.sink {
//            self.objectWillChange.send()
//        }
    }

    static func install(
        service: BrewService, processService: BrewProcessService, name: PackageIdentifier
    ) async throws -> BrewStreaming {
        let stream = try await processService.stream(command: .install(name))

        return BrewStreaming(service: service, processService: processService, stream: stream)
    }

    static func uninstall(
        service: BrewService, processService: BrewProcessService, name: PackageIdentifier
    ) async throws -> BrewStreaming {
        let stream = try await processService.stream(command: .uninstall(name))

        return BrewStreaming(service: service, processService: processService, stream: stream)
    }

    static func upgrade(
        service: BrewService, processService: BrewProcessService, name: PackageIdentifier
    ) async throws -> BrewStreaming {
        let stream = try await processService.stream(command: .upgrade(.package(name)))

        return BrewStreaming(service: service, processService: processService, stream: stream)
    }

    static func upgrade(
        service: BrewService, processService: BrewProcessService
    ) async throws -> BrewStreaming {
        let stream = try await processService.stream(command: .upgrade(.all))

        return BrewStreaming(service: service, processService: processService, stream: stream)
    }

//    public func done() async {
//        await MainActor.run {
//            self.stream = nil
//            self.objectWillChange.send()
//        }
//    }
}
