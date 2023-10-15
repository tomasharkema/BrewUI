//
//  BrewCache.swift
//
//
//  Created by Tomas Harkema on 01/09/2023.
//

import BrewShared
import Foundation
import SwiftData
import Inject

public actor BrewCache: ModelActor {
  public static let globalFetchLimit = 100
  public let modelExecutor: any ModelExecutor

  public nonisolated let modelContainer: ModelContainer

  fileprivate init() {
    #if DEBUG
      dispatchPrecondition(condition: .notOnQueue(.main))
    #endif
    let container = ModelContainer.brew
    modelContainer = container
    let context = ModelContext(container)
    modelExecutor = DefaultSerialModelExecutor(modelContext: context)
  }

  public func sync(all: any Sequence<InfoResultOnlyRemote>) throws {
    //    guard !all.isEmpty else {
    //      return
    //    }

    let core = PackageIdentifier.core
    let old = try modelContext.fetch(
      FetchDescriptor<PackageCache>(predicate: #Predicate { $0.tap == core })
    ).lazy.map {
      PackageCacheRemoteWrapper(package: $0)
    }

    let diff = Differ(old: old, new: all)

    try modelContext.transaction {
      for add in diff.adds {
        let item = diff.element(add)!
        try modelContext.insert(PackageCache(info: item))
      }

      if !diff.removes.isEmpty {
        let ids = diff.removes.map(\.id.description)
        try modelContext.delete(model: PackageCache.self, where: #Predicate {
          ids.contains($0.identifier)
        })
      }

      for update in diff.updates {
        if let item = diff.oldElement(update.id), let updated = diff.element(update.id) {
          try item.package.update(infoRemote: updated)
        } else {
          fatalError()
        }
        //        if let model = try self.package(by: update.id) {
        //          try model.update(infoRemote: diff.element(update.id)!)
        //        }
      }
    }
    try modelContext.save()
  }

//  public func sync(outdated: [InfoResponse]) throws {
//    let olds = try modelContext.fetch(
//      FetchDescriptor<PackageCache>()
//    )
//    let outdates = olds.map {
//      PackageByOutdated(package: $0)
//    }
//
//    let outdated = outdated.map {
//      PackageByOutdated(remote: $0)
//    }
//
//    let diff = Differ(old: outdates, new: outdated)
//
//    try modelContext.transaction {
//      for add in diff.adds {
//        if let model = try? self.package(by: add.id) {
//          model.outdated = true
//        }
//      }
//      for update in diff.updates {
//        if let model = try? self.package(by: update.id), let element = diff.element(update.id) {
//          model.outdated = element.outdated
//        }
//      }
//    }
//  }

  public func sync(installed: [InfoResponse]) throws -> [InfoResponse] {
    let old = try modelContext.fetch(
      FetchDescriptor<PackageCache>()
    )
    let oldSet = Set(old) // .byId())
    let allSet = Set(installed) // .byId())

    let diff = Differ(old: oldSet, new: allSet)

    try modelContext.transaction {
      for add in diff.adds {
        _ = try? self.packageGetOrCreate(info: diff.element(add)!)
//        InstalledCache.create(package: model!, modelContext: modelContext)
      }

//      if !diff.removes.isEmpty {
//        let idDescription = diff.removes.map(\.id.description)
////        try modelContext.delete(model: InstalledCache.self, where: #Predicate {
////          idDescription.contains($0.identifier)
////        })
//      }

      for update in diff.updates {
        let model = diff.oldElement(update.id)!
        let info = diff.element(update.id)!

        try model.update(info: info)
      }
    }
    return installed
  }

  public func sync(taps: [TapInfo]) throws {
    try modelContext.transaction {
      let old = try self.modelContext.fetch(FetchDescriptor<Tap>())

      let diff = Differ(old: old, new: taps)

      if !diff.updates.isEmpty {
        print("UPDATED!")
        fatalError()
      }

      for tap in diff.adds {
        let tapInfo = diff.element(tap)!

        if let tapModel = try self.tap(by: tap) {
          try tapModel.update(tapInfo: tapInfo)
        } else {
          try modelContext.insert(Tap(info: tapInfo))
        }
      }

      if !diff.removes.isEmpty {
        let removes = diff.removes
        try modelContext.delete(model: Tap.self, where: #Predicate {
          removes.contains($0.name)
        })
      }
    }
  }

  public func tap(by name: String) throws -> Tap? {
    var descriptor = FetchDescriptor<Tap>()
    descriptor.predicate = #Predicate {
      $0.name == name
    }
    return try modelContext.fetch(descriptor).first
  }

  public func package(by id: PackageIdentifier) throws -> PackageCache? {
    var descriptor = FetchDescriptor<PackageCache>()
    let identifier = id.description
    descriptor.predicate = #Predicate {
      $0.identifier == identifier
    }
    descriptor.fetchLimit = 1
    let result = try modelContext.fetch(descriptor).first
    return result
  }

  public func packageGetOrCreate(info: InfoResponse) throws -> PackageCache {
    if let model = try self.package(by: info.id) {
      try model.update(info: info)
      return model
    }

    let model = try PackageCache(info: info)
    try model.update(info: info)
    modelContext.insert(model)
    return model
  }

  public func packageGetOrCreate(info: InfoResultOnlyRemote) throws -> PackageCache {
    if let model = try self.package(by: info.id) {
      try model.update(infoRemote: info)
      return model
    }

    let modelNew = try PackageCache(info: info)
    try modelNew.update(infoRemote: info)
    modelContext.insert(modelNew)
    return modelNew
  }

  public func search(query: String) throws -> [PackageCache] {
    var descriptor = FetchDescriptor<PackageCache>()
    let query = query.lowercased()
    descriptor.predicate = #Predicate {
      $0.identifier.contains(query) || $0.desc.contains(query)
    }
    return try modelContext.fetch(descriptor)
  }

  func lastUpdated() throws -> LocalFileLastUpdated? {
    var descriptor = FetchDescriptor<LastUpdatedModel>(sortBy: [SortDescriptor(\.updatedDate, order: .reverse)])
    descriptor.fetchLimit = 1

    guard let lastUpdated = try modelContext.fetch(descriptor).first else {
      return nil
    }

    return LocalFileLastUpdated(
      updatedDate: lastUpdated.updatedDate,
      updatedHashValue: lastUpdated.updatedHashValue
    )
  }

  func updateLastUpdated(local: LocalFileLastUpdated) throws {
    let model = LastUpdatedModel(updatedDate: local.updatedDate, updatedHashValue: local.updatedHashValue)
    modelContext.insert(model)
    try modelContext.save()
  }
}

public extension ModelContainer {
  static var brew: ModelContainer {
    // swiftlint:disable:next force_try
    try! ModelContainer(
      for: PackageCache.self, Tap.self, LastUpdatedModel.self,
      configurations: ModelConfiguration("BrewUIDB", url: .brewStorage)
    )
  }
}

extension InjectedValues {
  var brewCache: BrewCache {
    get { Self[BrewCacheKey.self] }
    set { Self[BrewCacheKey.self] = newValue }
  }
}

private struct BrewCacheKey: InjectionKey {
  static var currentValue: BrewCache = .init()
}
