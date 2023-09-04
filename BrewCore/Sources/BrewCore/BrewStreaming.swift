//
//  File.swift
//  
//
//  Created by Tomas Harkema on 05/09/2023.
//

import Foundation
import Combine

@MainActor
public final class BrewStreaming: ObservableObject, Identifiable {

    private let service: BrewService

    public let id = UUID()

    private var streamCancellable: AnyCancellable?
    @Published public var stream: StreamStreamingAndTask

    init(service: BrewService, stream: StreamStreamingAndTask) {
        self.service = service
        self.stream = stream

        streamCancellable = stream.objectWillChange.sink {
            self.objectWillChange.send()
        }

#if DEBUG
        _printChanges()
#endif
    }

    public static func install(service: BrewService, name: PackageIdentifier) async throws -> BrewStreaming {
        let brew = try await service.whichBrew()
        let stream = await Process.stream(command: "\(brew.rawValue) install \(name.name)")


        return BrewStreaming(service: service, stream: stream)

//        await MainActor.run {
//            self.stream?.cancel()
//            streamCancellable = stream.objectWillChange.sink {
//                self.objectWillChange.send()
//            }
//            self.stream = stream
//        }
//        _ = try await stream.value
//        _ = try await service.update()
    }

    public static func uninstall(service: BrewService, name: PackageIdentifier) async throws -> BrewStreaming {
        let brew = try await service.whichBrew()
        let stream = await Process.stream(command: "\(brew.rawValue) uninstall \(name.name)")

        return BrewStreaming(service: service, stream: stream)
//        await MainActor.run {
//            self.stream?.cancel()
//            streamCancellable = stream.objectWillChange.sink {
//                self.objectWillChange.send()
//            }
//            self.stream = stream
//        }
//        try await stream.value
//        _ = try await service.update()
    }

    public static func upgrade(service: BrewService, name: PackageIdentifier) async throws -> BrewStreaming {
        let brew = try await service.whichBrew()
        let stream = await Process.stream(command: "\(brew.rawValue) upgrade \(name.name)")

        return BrewStreaming(service: service, stream: stream)
//        await MainActor.run {
//            self.stream?.cancel()
//            streamCancellable = stream.objectWillChange.sink {
//                self.objectWillChange.send()
//            }
//            self.stream = stream
//        }
//        try await stream.value
//        _ = try await service.update()
    }

//    public func done() async {
//        await MainActor.run {
//            self.stream = nil
//            self.objectWillChange.send()
//        }
//    }
}
