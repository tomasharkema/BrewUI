//
//  BrewUpdateService.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import BrewShared
import Foundation
import Injected
import OSLog
import Processed

@MainActor
public final class BrewUpdateService: ObservableObject, LoadableSupport {
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: "BrewUpdateService"
  )

  @Injected(\.brewService)
  private var service: BrewService

  @Injected(\.helperProcessService)
  private var processService

  @Published
  public private(set) var all: LoadableState<Void> = .absent

  @Published
  public private(set) var updating: LoadableState<UpdateState> = .absent

  @Published
  public private(set) var upgrading: LoadableState<PackageState> = .absent

  @Published
  public private(set) var installing: LoadableState<PackageState> = .absent

  @Published
  public private(set) var uninstalling: LoadableState<PackageState> = .absent

  @Published
  public private(set) var stream: BrewStreaming?

  public init() {
//        stream?.objectWillChange.sink {
//            self.objectWillChange.send()
//        }
  }

  public func update() async {
    let task = load(\.all, priority: .medium) {
      print("updatingAll", "START!")

      let taskInner = self.load(\.updating, priority: .medium) { yield in
        do {
          
          yield(.loaded(.initialSyncing))
          await self.service.initialSyncIfNeeded()
          yield(.loaded(.initialSynced))

          self.logger.info("UPDATEING....")
          let res = try await self.processService.update()
          self.logger.info("UPDATE DONE! \(String(describing: res)), fetching info...")
          yield(.loaded(.updated(res)))
          _ = try await self.service.fetchInfo()
          self.logger.info("UPDATE DONE!")
          yield(.loaded(.synced))
        } catch {
          print(error)
          throw error
        }
      }
      await taskInner.value

      print("updatingAll", "DONE!")
    }

    await task.value
  }

  public func upgradeAll() async throws {
    let stream = try await service.upgrade(service: processService)
    self.stream = stream

    load(\.upgrading, priority: .medium) { yield in
      // wait for streaming result
      try await stream.stream.task.value
      yield(.loaded(.executed))
      _ = await self.update()
      yield(.loaded(.updated))
    }
  }

  public func upgrade(name: PackageIdentifier) async throws {
    let stream = try await service.upgrade(service: processService, name: name)
    self.stream = stream

    load(\.upgrading, priority: .medium) { yield in
      // wait for streaming result
      try await stream.stream.task.value
      yield(.loaded(.executed))
      _ = await self.update()
      yield(.loaded(.updated))
    }
  }

  public func install(name: PackageIdentifier) async throws {
    let stream = try await service.install(service: processService, name: name)
    self.stream = stream

    load(\.installing, priority: .medium) { yield in
      // wait for streaming result
      try await stream.stream.task.value
      yield(.loaded(.executed))
      _ = await self.update()
      yield(.loaded(.updated))
    }
  }

  public func uninstall(name: PackageIdentifier) async throws {
    let stream = try await service.uninstall(service: processService, name: name)
    self.stream = stream

    load(\.uninstalling, priority: .medium) { yield in
      // wait for streaming result
      try await stream.stream.task.value
      yield(.loaded(.executed))
      _ = await self.update()
      yield(.loaded(.updated))
    }
  }

  public var isAnyLoading: Bool {
    updating.isLoading || upgrading.isLoading || installing.isLoading || uninstalling.isLoading
  }

  public func streamIsDone() {
    stream = nil
  }
}

public extension UpdateState {
  var isDone: Bool {
    switch self {
    case .updated, .initialSynced, .initialSyncing:
      false
    case .synced:
      true
    }
  }
}

public extension LoadableState<UpdateState> {
  var isDone: Bool {
    switch self {
    case let .loaded(state):
      state.isDone

    default:
      false
    }
  }
}

// extension InjectedValues {
//    public var brewUpdateService: BrewUpdateService {
//        get { Self[BrewUpdateServiceKey.self] }
//        set { Self[BrewUpdateServiceKey.self] = newValue }
//    }
// }
//
// private struct BrewUpdateServiceKey: InjectionKey {
//    static var currentValue: BrewUpdateService = BrewUpdateService()
// }

// struct BrewUpdateServiceKey: EnvironmentKey {
//    static var defaultValue = BrewUpdateService()
// }
//
// extension EnvironmentValues {
//    public var brewUpdateService: BrewUpdateService {
//        get { self[BrewUpdateServiceKey.self] }
//        set { self[BrewUpdateServiceKey.self] = newValue }
//    }
// }
