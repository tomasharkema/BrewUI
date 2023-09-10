//
//  Streaming.swift
//
//
//  Created by Tomas Harkema on 07/09/2023.
//

import Foundation
import Combine

@MainActor
final class StreamStreaming: ObservableObject {
    @Published public var stream = [StreamElement]()
    @Published var isStreamingDone = false

    func append(level: StreamElement.Level, rawEntry: String) {
        append(StreamElement(level: level, rawEntry: rawEntry))
    }

    private func append(_ line: StreamElement) {
        stream.append(line)
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
    private let task: Task<Void, any Error>
    public let id = UUID()

    private var streamCancellable: AnyCancellable?

    init(stream: StreamStreaming, task: Task<Void, any Error>) {
        self.task = task
        streamCancellable = stream.objectWillChange.sink {
            self.objectWillChange.send()
        }

        stream.$stream.assign(to: &$stream)
        stream.$isStreamingDone.assign(to: &$isStreamingDone)
    }

    public func cancel() {
        task.cancel()
    }

    public var value: Void {
        get async throws {
            try await task.value
        }
    }

    public var attributed: AttributedString {
        stream.reduce(into: AttributedString()) { prev, new in
            prev += (new.attributedString + AttributedString("\n"))
        }
    }

    public var strings: [String] {
        stream.map(\.rawEntry)
    }

    public var out: any Sequence<String> {
        stream.lazy.filter { $0.level == .out }.map(\.rawEntry)
    }
}

public struct StreamElement {
    public let level: Level
    public let rawEntry: String
    public let attributedString: AttributedString

    init(level: Level, rawEntry: String) {
        self.level = level
        self.rawEntry = rawEntry

        switch level {
        case .dev:
            var attr = AttributedString(rawEntry)
            attr.foregroundColor = .blue
            attributedString = attr
        case .err:
            var attr = AttributedString(rawEntry)
            attr.foregroundColor = .red
            attributedString = attr
        case .out:
            let attr = AttributedString(rawEntry)
            attributedString = attr
        }
    }

    public enum Level {
        case out
        case err
        case dev
    }
}
