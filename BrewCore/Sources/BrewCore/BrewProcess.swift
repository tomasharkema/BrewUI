//
//  BrewProcess.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import BrewShared
import Combine
import Foundation
import OSLog

public final class BrewProcessService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "BrewProcessService"
    )

    public init() {}

    @BrewActor
    private var brewCached: Brew?

    @BrewActor
    private func whichBrew() async throws -> Brew {
        if let brewCached {
            return brewCached
        }

        let commandResult = try await (Process.shell(logger: logger, command: "which brew"))
        let result = commandResult.out.trimmingCharacters(in: .whitespacesAndNewlines)
        print("FOUND BREW: \(result)")
        brewCached = Brew(rawValue: result)
        return Brew(rawValue: result)
    }

    nonisolated func stream(
        brew brewOverride: Brew? = nil,
        command: String
    ) async throws -> StreamStreamingAndTask {
        let brew: Brew
        if let brewOverride {
            brew = brewOverride
        } else {
            brew = try await whichBrew()
        }
        return await Process.stream(logger: logger, command: "\(brew.rawValue) \(command)")
    }

    nonisolated func shell(brew brewOverride: Brew? = nil, command: String) async throws -> CommandOutput {
        let brew: Brew
        if let brewOverride {
            brew = brewOverride
        } else {
            brew = try await whichBrew()
        }
        return try await Process.shell(logger: logger, command: "\(brew.rawValue) \(command)")
    }

    nonisolated func infoFromBrew(command: String) async throws -> [InfoResult] {
        do {
            let stream = try await shell(command: command)
            try Task.checkCancellation()

            guard let data = stream.out.data(using: .utf8) else {
                throw NSError(domain: "data error", code: 0)
            }
            return try JSONDecoder().decode([InfoResult].self, from: data)
        } catch {
            logger.error("Error: \(error)")
            throw error
        }
    }

    nonisolated func infoFormulaInstalled() async throws -> [InfoResult] {
        try await infoFromBrew(command: "info --json=v1 --installed")
    }

    nonisolated func infoFormula(package: PackageIdentifier) async throws -> [InfoResult] {
        try await infoFromBrew(command: "info --json=v1 --formula \(package.nameWithoutCore)")
    }

    nonisolated func update() async throws -> UpdateResult {
        let res = try await shell(command: "update")

        if res.out.contains("Already up-to-date") || res.err.contains("Already up-to-date") {
            return .alreadyUpToDate
        }
        print(res.out, res.err)
        fatalError()
    }

    nonisolated func searchFormula(query: String) async throws -> [PackageIdentifier] {
        do {
            logger.info("Search for \(query)")
            let stream = try await shell(command: "search --formula \(query)")
            try Task.checkCancellation()
            return try stream.out.split(separator: "\n")
                .compactMap {
                    try PackageIdentifier(raw: String($0))
                }

        } catch {
            if error is CancellationError {
                logger.info("Search for \(query) cancelled")
            }
            throw error
        }
    }
}

enum UpdateResult {
    case alreadyUpToDate
}

enum BrewCommand {}

private extension Process {
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

    nonisolated static func shell(logger: Logger, command: String) async throws -> CommandOutput {
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
            throw StdErr(out: CommandOutput(out: output, err: outputErr), command: command)
        }

        return CommandOutput(out: output, err: outputErr)
    }

    nonisolated static func stream(logger: Logger, command: String) async -> StreamStreamingAndTask {
        let stream = await StreamStreaming()
        await stream.append(level: .dev, rawEntry: "EXECUTE: \(command)")
        let task = defaultShell(command: command)

        let pipe = Pipe()
        let pipeErr = Pipe()

        task.standardOutput = pipe
        task.standardError = pipeErr
        
        task.launch()

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
                await stream.append(
                    level: .dev,
                    rawEntry: "CODE: \(task.terminationStatus) \(termination)"
                )
                throw await StdErr(stream: stream.stream, command: command)
            }
        }

        return await StreamStreamingAndTask(stream: stream, task: awaitTask)
    }
}

@globalActor
actor BrewActor {
    static let shared = BrewActor()
}
