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

        let command = try await Process.shell(logger: logger, command: "which brew")
        let result = command.outString
        if !result.contains("brew") {
            throw NSError(domain: "brew not found", code: 42)
        }
        brewCached = Brew(rawValue: result)
        return Brew(rawValue: result)
    }

    nonisolated func stream(
        brew brewOverride: Brew? = nil,
        command: BrewCommand
    ) async throws -> StreamStreamingAndTask {
        let brew: Brew
        if let brewOverride {
            brew = brewOverride
        } else {
            brew = try await whichBrew()
        }
        return await Process.stream(logger: logger, command: "\(brew.rawValue) \(command.command)")
    }

    nonisolated func shellStreaming(brew brewOverride: Brew? = nil, command: BrewCommand) async throws -> CommandOutput {
        let brew: Brew
        if let brewOverride {
            brew = brewOverride
        } else {
            brew = try await whichBrew()
        }
        return try await Process.shellStreaming(logger: logger, command: "\(brew.rawValue) \(command.command)")
    }

    nonisolated func shell(brew brewOverride: Brew? = nil, command: BrewCommand) async throws -> CommandOutput {
        let brew: Brew
        if let brewOverride {
            brew = brewOverride
        } else {
            brew = try await whichBrew()
        }
        return try await Process.shell(logger: logger, command: "\(brew.rawValue) \(command.command)")
    }

    nonisolated func infoFromBrew(command: InfoCommand) async throws -> [InfoResult] {
        do {
            let stream = try await shell(command: .info(command))
            try Task.checkCancellation()

            guard let data = stream.outString.data(using: .utf8) else {
                throw NSError(domain: "data error", code: 0)
            }
            return try JSONDecoder().decode([InfoResult].self, from: data)
        } catch {
            logger.error("Error: \(error)")
            throw error
        }
    }

    nonisolated func infoFormulaInstalled() async throws -> [InfoResult] {
        try await infoFromBrew(command: .installed)
    }

    nonisolated func infoFormula(package: PackageIdentifier) async throws -> [InfoResult] {
        try await infoFromBrew(command: .formula(package))
    }

    nonisolated func update() async throws -> UpdateResult {
        let res = try await shell(command: .update)
        return try .init(res)
    }

    nonisolated func searchFormula(query: String) async throws -> [PackageIdentifier] {
        do {
            logger.info("Search for \(query)")
            let stream = try await shell(command: .search(query))
            try Task.checkCancellation()
            return try stream.outString.split(separator: "\n")
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

private extension Process {
    func awaitTermination() async throws -> Process.TerminationReason {
        let result = try await withTaskCancellationHandler(operation: {
            return try await withCheckedThrowingContinuation { res in
                do {
                    terminationHandler = {
                        res.resume(returning: $0.terminationReason)
                    }
                    try run()
                } catch {
                    res.resume(throwing: error)
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

        let out = CommandOutput(stream: [
            .init(level: .out, rawEntry: output),
            .init(level: .err, rawEntry: outputErr)
        ])

        guard termination == .exit else {
            throw StdErr(out: out, command: command)
        }

        return out
    }

    nonisolated static func shellStreaming(logger: Logger, command: String) async throws -> CommandOutput {
        logger.info("EXECUTING \(command)")
        let streaming = await stream(logger: logger, command: command)
        logger.info("STREAMING \(command)")
        defer { logger.info("STREAMING DONE \(command)") }
        _ = try await streaming.task.value

        logger.info("STREAMING DONE \(command)")
        defer { logger.info("STREAMING DONE DONE \(command)") }

        return await CommandOutput(stream: streaming.streaming.stream)

//        logger.info("EXECUTE: \(command)")
//
//        let task = defaultShell(command: command)
//
//        let pipe = Pipe()
//        let pipeErr = Pipe()
//
//        task.standardOutput = pipe
//        task.standardError = pipeErr
//
//        let outputTask = Task.detached {
//            let data = pipe.fileHandleForReading.readDataToEndOfFile()
//            let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
//            let output = String(data: data, encoding: .utf8)!
//                .trimmingCharacters(in: .whitespacesAndNewlines)
//            let outputErr = String(data: dataErr, encoding: .utf8)!
//                .trimmingCharacters(in: .whitespacesAndNewlines)
//
//            return (output, outputErr)
//        }
//
//        let termination = try await task.awaitTermination()
//        try Task.checkCancellation()
//        let (output, outputErr) = await outputTask.value
//        try Task.checkCancellation()
//
//        guard termination == .exit else {
//            throw StdErr(out: CommandOutput(out: output, err: outputErr), command: command)
//        }
//
//        return CommandOutput(out: output, err: outputErr)
    }

    nonisolated static func stream(logger: Logger, command: String) async -> StreamStreamingAndTask {
        let stream = await StreamStreaming()
        await stream.append(level: .dev, rawEntry: "EXECUTE: \(command)")
        let task = defaultShell(command: command)

        let pipe = Pipe()
        let pipeErr = Pipe()

        task.standardOutput = pipe
        task.standardError = pipeErr

        let receiveStreamTask = Task.detached {
            logger.info("\(command) stream started!!")
            defer {
                logger.info("\(command) stream finished!!")
            }
            for try await line in pipe.fileHandleForReading.bytes.lines {
//                logger.info("\(command) received: \(line)")
                await stream.append(level: .out, rawEntry: line)
            }
        }

        let receiveStreamErrTask = Task.detached {
            logger.info("\(command) stream err started!!")
            defer {
                logger.info("\(command) stream err finished!!")
            }
            for try await line in pipeErr.fileHandleForReading.bytes.lines {
//                logger.info("\(command) received err: \(line)")
                await stream.append(level: .err, rawEntry: line)
            }
        }

        let awaitTask = Task.detached {

            logger.info("\(command) awaitTask")
            defer { logger.info("\(command) awaitTask done") }

            let termination = try await task.awaitTermination()
            logger.info("\(command) terminated \(termination.rawValue)")
            try Task.checkCancellation()

            await stream.append(level: .dev, rawEntry: "Done: \(command)")

            logger.info("\(command) waiting for stream tasks")
            let _ = try await (receiveStreamTask.value, receiveStreamErrTask.value)

            try Task.checkCancellation()

            if termination != .exit {
                await stream.append(
                    level: .dev,
                    rawEntry: "CODE: \(task.terminationStatus) \(termination)"
                )
                await stream.done()
                throw await StdErr(stream: stream.stream, command: command)
            }
            await stream.done()
        }

        return await StreamStreamingAndTask(stream: stream, task: awaitTask)
    }
}

@globalActor
actor BrewActor {
    static let shared = BrewActor()
}
