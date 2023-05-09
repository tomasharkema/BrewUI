//
//  ProcessHelper.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import Foundation

extension Process {
  static func defaultShell() -> Process {
    let task = Process()
    let userShell = ProcessInfo.processInfo.environment["SHELL"]

    task.launchPath = userShell
    task.standardInput = nil

    return task
  }

  static func shell(command: String) async throws -> String {
    try await Task {
      print("EXECUTE: \(command)")

      let task = defaultShell()
      task.arguments = ["-l", "-c", command]

      let pipe = Pipe()
      let pipeErr = Pipe()

      task.standardOutput = pipe
      task.standardError = pipeErr

      task.launch()

      let (output, outputErr) = await Task.detached {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
          .trimmingCharacters(in: .whitespacesAndNewlines)
        let outputErr = String(data: dataErr, encoding: .utf8)!
          .trimmingCharacters(in: .whitespacesAndNewlines)

        return (output, outputErr)
      }.value

      await withTaskCancellationHandler(operation: {
        task.waitUntilExit()
      }, onCancel: {
        task.terminate()
      })

      if task.terminationStatus == EXIT_SUCCESS {
        return output
      }

      throw StdErr(message: output + "\n" + outputErr)
    }.value
  }

  static func stream(command: String) -> StreamStreaming {
    let stream = StreamStreaming()

    let task = Task.detached {
      defer {
        Task {
          await MainActor.run {
            stream.stream.isStreamingDone = true
            stream.objectWillChange.send()
          }
        }
      }

      print("EXECUTE: \(command)")

      await MainActor.run {
        stream.stream.stream += "EXECUTE: \(command)\n"
        stream.objectWillChange.send()
      }

      let task = defaultShell()
      task.arguments = ["-l", "-c", command]

      let pipe = Pipe()
      let pipeErr = Pipe()

      task.standardOutput = pipe
      task.standardError = pipeErr

      task.launch()

      pipe.fileHandleForReading.readabilityHandler = { handle in

        let newData: Data = handle.availableData
        Task.detached {
          if newData.count == 0 {
            handle.readabilityHandler = nil // end of data signal is an empty data object.
          } else {
            await MainActor.run {
              stream.stream.stream += String(data: newData, encoding: .utf8) ?? ""
              stream.objectWillChange.send()
            }
          }
        }
      }

      pipeErr.fileHandleForReading.readabilityHandler = { handle in
        let newData: Data = handle.availableData
        Task.detached {
          if newData.count == 0 {
            handle.readabilityHandler = nil // end of data signal is an empty data object.
          } else {
            if let errorString = String(data: newData, encoding: .utf8) {
              await MainActor.run {
                stream.stream.stream += "ERR: \(errorString)"
                stream.objectWillChange.send()
              }
            }
          }
        }
      }

      task.waitUntilExit()

      if task.terminationStatus != EXIT_SUCCESS {
        await MainActor.run {
          stream.stream.stream += "CODE: \(task.terminationStatus)"
          stream.objectWillChange.send()
        }

        throw NSError(domain: "EXIT_NOT_SUCCESS", code: Int(task.terminationStatus))
      }
    }

//    await stream.set(task: task)
    stream.task = task

    return stream
  }
}

class StreamStreaming: ObservableObject, Identifiable {
  let id = UUID()
  @MainActor @Published var stream = StreamOutput(stream: "", isStreamingDone: false)
  var task: Task<Void, Error>?
}
