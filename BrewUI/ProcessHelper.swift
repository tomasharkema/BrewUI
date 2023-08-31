//
//  ProcessHelper.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import AsyncAlgorithms
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
        try await Task {
            logger.info("EXECUTE: \(command)")

            let task = defaultShell(command: command)

            let pipe = Pipe()
            let pipeErr = Pipe()

            task.standardOutput = pipe
            task.standardError = pipeErr

            task.launch()

            let (output, outputErr) = await Task {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)!
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let outputErr = String(data: dataErr, encoding: .utf8)!
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                return (output, outputErr)
            }.value

            await withTaskCancellationHandler(operation: { () async in
                await withCheckedContinuation { res in
                    task.terminationHandler = { _ in
                        res.resume()
                    }
                }
            }, onCancel: {
                task.terminate()
            })

            if task.terminationStatus == EXIT_SUCCESS {
                return output
            }

            throw StdErr(message: output + "\n" + outputErr, command: command)
        }.value
    }

    static func stream(command: String) async -> StreamStreamingAndTask {
        let stream = StreamStreaming()
        await stream.append("EXECUTE: \(command)\n\n")
        let task = defaultShell(command: command)

        let pipe = Pipe()
        let pipeErr = Pipe()

        task.standardOutput = pipe
        task.standardError = pipeErr

        let stdoutSequence = pipe.fileHandleForReading.bytes.lines.map {
            AttributedString($0)
        }
        let stderrSequence = pipeErr.fileHandleForReading.bytes.lines.map {
            var string = AttributedString($0)
            string.foregroundColor = .red
            return string
        }

        let sequence = merge(stdoutSequence, stderrSequence)

        let receiveStreamTask = Task {
            logger.info("stream started!!")
            for try await line in sequence {
                await stream.append(line)
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

            await stream.append("\n\nDone: \(command)\n\n")

            try await receiveStreamTask.value

            if task.terminationStatus != EXIT_SUCCESS {
                await stream.append("\n\nCODE: \(task.terminationStatus)")
                throw await StdErr(message: stream.stream.description, command: command)
            }
        }

        return StreamStreamingAndTask(stream: stream, task: awaitTask)
    }
}

class StreamStreaming: ObservableObject {
    @MainActor @Published var stream = AttributedString("")
    @MainActor @Published var isStreamingDone = false

    @MainActor
    func append(_ line: AttributedString) {
        stream.append(line)
        stream.append(AttributedString("\n"))
    }

    @MainActor
    func append(_ line: String) {
        var string = AttributedString(line)
        string.foregroundColor = .blue
        stream.append(string)
        stream.append(AttributedString("\n"))
    }
}

class StreamStreamingAndTask: ObservableObject, Identifiable {
    @MainActor @Published var stream = AttributedString("")
    @MainActor @Published var isStreamingDone = false
    private let task: Task<Void, Error>
    let id = UUID()

    init(stream: StreamStreaming, task: Task<Void, Error>) {
        self.task = task
        stream.$stream.assign(to: &$stream)
        stream.$isStreamingDone.assign(to: &$isStreamingDone)
    }

    func cancel() {
        task.cancel()
    }

    public var value: Void {
        get async throws {
            try await task.value
        }
    }
}
