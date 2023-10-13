//
//  Dependencies.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import BrewCore

import SwiftData

@MainActor
final class Dependencies {
  private static var sharedTask: Task<Dependencies, any Error>?

  let modelContainer: ModelContainer
  let updateService: BrewUpdateService

  init() async throws {
    modelContainer = .brew
    updateService = BrewUpdateService()
  }
  static func shared() async throws -> Dependencies {
    if let sharedTask {
      return try await sharedTask.value
    }
    let depsTask = Task {
      try await Dependencies()
    }
    sharedTask = depsTask
    return try await depsTask.value
  }
}
