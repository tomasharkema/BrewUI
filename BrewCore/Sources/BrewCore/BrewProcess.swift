//
//  ProcessHelper.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import Combine
import Foundation
import OSLog

private let logger = Logger(subsystem: "BrewUI", category: "Process")

class BrewProcess {
    @BrewActor
    static private var brewCached: Brew?

    @BrewActor
    static func whichBrew() async throws -> Brew {
        if let brewCached {
            return brewCached
        }

        let result = try await (Process.shell(command: "which brew"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        print("FOUND BREW: \(result)")
        brewCached = Brew(rawValue: result)
        return Brew(rawValue: result)
    }

    static func stream(brew brewOverride: Brew? = nil, command: String) async throws -> StreamStreamingAndTask {
        let brew: Brew
        if let brewOverride {
            brew = brewOverride
        } else {
            brew = try await whichBrew()
        }
        return await Process.stream(command: "\(brew.rawValue) \(command)")
    }

    static func shell(brew brewOverride: Brew? = nil, command: String) async throws -> String {
        let brew: Brew
        if let brewOverride {
            brew = brewOverride
        } else {
            brew = try await whichBrew()
        }
        return try await Process.shell(command: "\(brew.rawValue) \(command)")
    }
}

fileprivate extension Process {
    func awaitTermination() async throws -> Process.TerminationReason {
        let result = await withTaskCancellationHandler(operation: { () async in
            await withCheckedContinuation { res in
                terminationHandler = {
                    res.resume(returning: $0.terminationReason)
                }
            }
        }, onCancel: {
            terminate()
        })
        try Task.checkCancellation()
        return result
    }
}

fileprivate extension Process {

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

        let outputTask = Task.detached {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)!
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let outputErr = String(data: dataErr, encoding: .utf8)!
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return (output, outputErr)
        }

        let termination = try await task.awaitTermination()
        try Task.checkCancellation()
        let (output, outputErr) = await outputTask.value
        try Task.checkCancellation()

        guard termination == .exit else {
            throw StdErr(stdout: output, stderr: outputErr, command: command)
        }

        return output
    }

    static func stream(command: String) async -> StreamStreamingAndTask {
        let stream = await StreamStreaming()
        await stream.append(level: .dev, rawEntry: "EXECUTE: \(command)")
        let task = defaultShell(command: command)

        let pipe = Pipe()
        let pipeErr = Pipe()

        task.standardOutput = pipe
        task.standardError = pipeErr

        let stdoutSequence = pipe.fileHandleForReading.bytes.lines
        let stderrSequence = pipeErr.fileHandleForReading.bytes.lines

        let receiveStreamTask = Task.detached {
            logger.info("stream started!!")
            defer {
                logger.info("stream finished!!")
            }
            for try await line in stdoutSequence {
                await stream.append(level: .out, rawEntry: line)
            }
        }

        let receiveStreamErrTask = Task.detached {
            logger.info("stream err started!!")
            defer {
                logger.info("stream err finished!!")
            }
            for try await line in stderrSequence {
                await stream.append(level: .err, rawEntry: line)
            }
        }

        let awaitTask = Task.detached {
            defer {
                Task { @MainActor in
                    stream.isStreamingDone = true
                }
            }

            let termination = try await task.awaitTermination()

            try Task.checkCancellation()

            await stream.append(level: .dev, rawEntry: "Done: \(command)")

            let _ = try await (receiveStreamTask.value, receiveStreamErrTask.value)

            try Task.checkCancellation()

            if termination != .exit {
                await stream.append(level: .dev, rawEntry: "CODE: \(task.terminationStatus)")
                throw await StdErr(stream: stream.stream, command: command)
            }
        }

        return await StreamStreamingAndTask(stream: stream, task: awaitTask)
    }
}
