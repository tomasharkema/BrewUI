//
//  PackageCacheRemoteWrapper.swift
//
//
//  Created by Tomas Harkema on 02/10/2023.
//

public struct PackageCacheRemoteWrapper: Hashable {
  public let package: PackageCache

  public init(package: PackageCache) {
    self.package = package
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(package.stableHash)
  }
}

extension PackageCacheRemoteWrapper: Identifiable {
    public var id: PackageIdentifier {
      package.id
    }
}
