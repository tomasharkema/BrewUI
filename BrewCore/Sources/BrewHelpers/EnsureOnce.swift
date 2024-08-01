//
//  EnsureOnce.swift
//
//
//  Created by Tomas Harkema on 21/10/2023.
//

import Foundation

public class EnsureOnce: Sendable {
  private static var handlers = SynchronizedDictionary<HandlerLocation, Task<Any, any Error>>()//[HandlerLocation: Task<Any, any Error>]()

  public static func once<ResultType>(
    _ handler: @Sendable @escaping () async throws -> ResultType,
    file: String = #file, line: UInt = #line, function: String = #function
  ) async throws -> ResultType {
    let handlerLocation = HandlerLocation(file: file, line: line, function: function)

    if let existingHandler = await handlers[handlerLocation] {
      // swiftlint:disable:next force_cast
      return try await existingHandler.value as! ResultType
    }

    let task = Task {
      do {
        return try await handler()
      } catch {
        throw error
      }
    }

    await handlers.set(handlerLocation, Task {
      // swiftlint:disable:next force_cast
      try await task.value as Any
    })

    do {
      let result = try await task.value
      await handlers.removeValue(forKey: handlerLocation)
      return result
    } catch {
      await handlers.removeValue(forKey: handlerLocation)
      throw error
    }
  }
}

struct HandlerLocation: Hashable {
  let file: String
  let line: UInt
  let function: String
}

public actor SynchronizedDictionary<Key: Hashable, Value> {
  private var dict: [Key: Value] = [:]

  public subscript(key: Key) -> Value? {
    get {
      dict[key]
    }

    set {
      self.dict[key] = newValue
    }
  }

  public func set(_ key: Key, _ value: Value) {
    self.dict[key] = value
  }

  public func removeValue(forKey key: Key) {
    self.dict.removeValue(forKey: key)
  }
}
