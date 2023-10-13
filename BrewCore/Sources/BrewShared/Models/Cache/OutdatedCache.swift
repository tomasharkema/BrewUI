//
//  OutdatedCache.swift
//  
//
//  Created by Tomas Harkema on 13/10/2023.
//

import Foundation
import SwiftData

//@Model
//public final class OutdatedCache: PackageCachable {
//  
//  @Relationship
//  public var package: PackageCache!
//  
//  @Attribute
//  public var lastUpdated: Date
//  @Attribute(.unique)
//  public var identifier: PackageIdentifierString
//  @Attribute
//  public var hasInstalledVersion: Bool
//  @Attribute
//  public var hasInstalledAsDependencyVersion: Bool
//
//  private init(package: PackageCache) {
//    self.package = nil
//    self.lastUpdated = .now
//    self.identifier = package.identifier
//    self.hasInstalledVersion = package.hasInstalledVersion
//    self.hasInstalledAsDependencyVersion = package.hasInstalledAsDependencyVersion
//  }
//
//  public static func create(package: PackageCache, modelContext: ModelContext) {
//    let model = OutdatedCache(package: package)
//    model.package = package
//    modelContext.insert(model)
//  }
//}
//
//extension OutdatedCache: Identifiable {
//  public var id: PackageIdentifier {
//    package.id
//  }
//}
