//
//  ProcessHelper.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import Combine
import Foundation
import OSLog

let logger = Logger(subsystem: "BrewUI", category: "Process")

extension Process {
    static func defaultShell(command: String) -> Process {
        let task = Process()
        let userShell = ProcessInfo.processInfo.environment["SHELL"]
        // sandbox-exec -p '(version 1)(allow default)(deny network*)(deny file-read-data (regex
        // "^/Users/'$USER'/(Documents|Desktop|Developer|Movies|Music|Pictures)"))'
        task.launchPath = userShell ?? "/bin/sh"
        task.arguments = [
            "-l", "-c", command,
        ]
        task.standardInput = nil

        return task
    }

    static func shell(command: String) async throws -> String {
        logger.info("EXECUTE: \(command)")

        let task = defaultShell(command: command)

        let pipe = Pipe()
        let pipeErr = Pipe()

        task.standardOutput = pipe
        task.standardError = pipeErr

        task.launch()

        let outputTask = await Task {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)!
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let outputErr = String(data: dataErr, encoding: .utf8)!
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return (output, outputErr)
        }

        await withTaskCancellationHandler(operation: { () async in
            await withCheckedContinuation { res in
                task.terminationHandler = { _ in
                    res.resume()
                }
            }
        }, onCancel: {
            task.terminate()
        })

        let (output, outputErr) = await outputTask.value

        try Task.checkCancellation()

        guard task.terminationStatus == EXIT_SUCCESS else {
            throw StdErr(message: output + "\n" + outputErr, command: command)
        }

        return output
    }

    static func stream(command: String) async -> StreamStreamingAndTask {
        let stream = StreamStreaming()
        await stream.append(StreamElement(level: .dev, rawEntry: "EXECUTE: \(command)\n\n"))
        let task = defaultShell(command: command)

        let pipe = Pipe()
        let pipeErr = Pipe()

        task.standardOutput = pipe
        task.standardError = pipeErr

        let stdoutSequence = pipe.fileHandleForReading.bytes.lines
        let stderrSequence = pipeErr.fileHandleForReading.bytes.lines

        let receiveStreamTask = Task {
            logger.info("stream started!!")
            for try await line in stdoutSequence {
                await stream.append(StreamElement(level: .out, rawEntry: line))
            }
            logger.info("stream finished!!")
        }

        let receiveStreamErrTask = Task {
            logger.info("stream started!!")
            for try await line in stderrSequence {
                await stream.append(StreamElement(level: .err, rawEntry: line))
            }
            logger.info("stream finished!!")
        }

        let awaitTask = Task {
            defer {
                Task { @MainActor in
                    stream.isStreamingDone = true
                }
            }

            task.launch()

            await withTaskCancellationHandler(operation: { () async in
                await withCheckedContinuation { res in
                    task.terminationHandler = { _ in
                        res.resume()
                    }
                }
            }, onCancel: {
                task.terminate()
            })

            try Task.checkCancellation()

            await stream.append(StreamElement(level: .dev, rawEntry: "\n\nDone: \(command)\n\n"))

            try await receiveStreamTask.value

            try Task.checkCancellation()

            if task.terminationStatus != EXIT_SUCCESS {
                await stream.append(StreamElement(level: .dev, rawEntry: "\n\nCODE: \(task.terminationStatus)"))
                throw StdErr(message: stream.stream.description, command: command)
            }
        }

        return await StreamStreamingAndTask(stream: stream, task: awaitTask)
    }
}

public struct StreamElement {
    public let level: Level
    public let rawEntry: String
    public let attributedString: AttributedString

    init(level: Level, rawEntry: String) {
        self.level = level
        self.rawEntry = rawEntry
//        self.attributedString = attributedString

        switch level {
        case .dev:
            var a = AttributedString(rawEntry)
            a.foregroundColor = .blue
            self.attributedString = a
        case .err:
            var a = AttributedString(rawEntry)
            a.foregroundColor = .red
            self.attributedString = a
        case .out:
            var a = AttributedString(rawEntry)
            self.attributedString = a
        }
    }

    public enum Level {
        case out
        case err
        case dev
    }
}

final class StreamStreaming: ObservableObject {
    @Published public var stream = [StreamElement]()
    @MainActor @Published var isStreamingDone = false

    @MainActor
    func append(_ line: StreamElement) {
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
    private let task: Task<Void, Error>
    public let id = UUID()

    init(stream: StreamStreaming, task: Task<Void, Error>) {
        self.task = task
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
