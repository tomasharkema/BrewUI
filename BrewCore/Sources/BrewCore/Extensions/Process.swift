//
//  Process.swift
//  
//
//  Created by Tomas Harkema on 05/10/2023.
//

import Foundation
import OSLog

extension Process {
    func awaitTermination() async throws -> Process.TerminationReason {
        let result = try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { res in
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
            "-l", "-c", command
        ]
        task.standardInput = nil

        return task
    }

    nonisolated static func shell(
        logger: Logger, command: String
    ) async throws -> CommandOutput {
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

    nonisolated static func shellStreaming(
        logger: Logger,
        command: String
    ) async throws -> CommandOutput {
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

    nonisolated static func stream(
        logger: Logger,
        command: String
    ) async -> StreamStreamingAndTask {
        let stream = StreamStreaming()
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
            _ = try await (receiveStreamTask.value, receiveStreamErrTask.value)

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
