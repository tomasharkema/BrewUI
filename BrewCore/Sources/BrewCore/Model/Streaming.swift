//
//  Streaming.swift
//
//
//  Created by Tomas Harkema on 07/09/2023.
//

import Combine
import Foundation

final actor StreamStreaming: ObservableObject {
    @Published public var stream = [StreamElement]()
    @Published var isStreamingDone = false

    func append(level: StreamElement.Level, rawEntry: String) {
        append(StreamElement(level: level, rawEntry: rawEntry))
    }

    private func append(_ line: StreamElement) {
        stream.append(line)
    }

    func done() {
        isStreamingDone = true
    }

    //    @MainActor
    //    func append(_ line: String) {
    //        var string = AttributedString(line)
    //        string.foregroundColor = .blue
    //        streamAttributed.append(string)
    //        streamAttributed.append(AttributedString("\n"))
    //        stream.append(line)
    //    }
}

@MainActor
public final class StreamStreamingAndTask: ObservableObject, Identifiable {
    @Published public var stream = [StreamElement]()
    @Published public var isStreamingDone = false
    let task: Task<Void, any Error>
    public let id = UUID()
    let streaming: StreamStreaming

    private var streamCancellable: AnyCancellable?

    init(stream: StreamStreaming, task: Task<Void, any Error>) async {
        streaming = stream
        self.task = task

        await streaming.$stream.receive(on: DispatchQueue.main).assign(to: &self.$stream)
        await streaming.$isStreamingDone.receive(on: DispatchQueue.main)
            .assign(to: &$isStreamingDone)

        streamCancellable = stream.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink {
                self.objectWillChange.send()
            }

//        await stream.$stream.receive(on: DispatchQueue.main).assign(to: &$stream)
//        await stream.$isStreamingDone.receive(on: DispatchQueue.main).assign(to:
//        &$isStreamingDone)
    }

    public func cancel() {
        task.cancel()
    }

    public var value: Void {
        get async throws {
            try await task.value
        }
    }
}
