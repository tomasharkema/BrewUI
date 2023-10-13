//
//  PackageInfo.swift
//
//
//  Created by Tomas Harkema on 02/09/2023.
//

import SwiftMacros

@AddAssociatedValueVariable
public enum PackageInfo: Hashable, Equatable {
  case remote(InfoResultOnlyRemote)
  case cached(PackageCache)
}

extension PackageInfo: Identifiable {
  public var id: Int {
    hashValue
  }
}

extension PackageInfo {
  
  public var versions: (any Collection<Version>)? {
    cachedValue?.versions
  }

  public var firstInstalledVersion: SemanticVersion? {
    versions?.first { !$0.isDependency }?.version
  }

  public var firstInstalledAsDependency: SemanticVersion? {
    versions?.first { !$0.isDependency }?.version
  }

  public var versionsStable: SemanticVersion? {
    switch self {
    case .remote:
      nil

    case let .cached(cached):
      cached.versionsStable.map { SemanticVersion(stringLiteral: $0) }
    }
  }

  public var identifier: PackageIdentifier {
    get throws {
      switch self {
      case let .remote(remote):
        remote.identifier

      case let .cached(cached):
        try PackageIdentifier(raw: cached.identifier)
      }
    }
  }

  public var outdated: Bool {
    switch self {
    case .remote:
      false // cause not installed!

    case let .cached(pkg):
      pkg.outdated
    }
  }

  public var license: String? {
    switch self {
    case let .remote(remote):
      remote.license

    case let .cached(cached):
      cached.license
    }
  }
  
  public var homepage: String {
    switch self {
    case let .remote(remote):
      remote.homepage

    case let .cached(cached):
      cached.homepage
    }
  }

  var remote: InfoResultOnlyRemote? {
    switch self {
    case let .remote(remote):
      remote

    case .cached:
      nil
    }
  }

  var cached: PackageCache? {
    switch self {
    case let .cached(cached):
      cached

    case .remote:
      nil
    }
  }
}
