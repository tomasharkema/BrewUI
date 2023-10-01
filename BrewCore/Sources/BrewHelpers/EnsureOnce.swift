//
//  EnsureOnce.swift
//
//
//  Created by Tomas Harkema on 09/09/2023.
//

import Foundation

public actor EnsureOnce {
    private static var handlers = [HandlerLocation: Task<Void, any Error>]()

    public static func once(
        _ handler: @escaping () async throws -> Void,
        file: String = #file, line: UInt = #line, function: String = #function
    ) async throws {
        let handlerLocation = HandlerLocation(file: file, line: line, function: function)

        if let existingHandler = handlers[handlerLocation] {
            return try await existingHandler.value
        }

        defer {
            handlers[handlerLocation] = nil
        }

        let task = Task {
            do {
                return try await handler()
            } catch {
                throw error
            }
        }

        handlers[handlerLocation] = task
        return try await task.value
    }
}

struct HandlerLocation: Hashable {
    let file: String
    let line: UInt
    let function: String
}
