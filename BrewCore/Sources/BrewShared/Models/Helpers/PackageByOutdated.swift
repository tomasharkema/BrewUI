//
//  PackageByOutdated.swift
//
//
//  Created by Tomas Harkema on 13/10/2023.
//

import Foundation

public struct PackageByOutdated: Equatable, Hashable, Identifiable {
  public let id: PackageIdentifier
  public let outdated: Bool

  public init(package: PackageCache) {
    self.id = package.id
    self.outdated = package.outdated
  }

  public init(remote: InfoResponse) {
    self.id = remote.id
    self.outdated = remote.outdated
  }
}
