//
//  PackageCache.swift
//  BrewUI
//
//  Created by Tomas Harkema on 31/08/2023.
//

import Foundation
import SwiftData

public typealias PackageIdentifierString = String

@Model
public final class PackageCache {
  @Attribute(.unique)
  public private(set) var identifier: PackageIdentifierString

  @Attribute
  public private(set) var json: Data

  @Attribute
  public private(set) var stableHash: String

  @Attribute
  public private(set) var lastUpdated: Date
  @Attribute
  public private(set) var checksum: String
//  @Attribute
//  public private(set) var sortValue: String
  @Attribute
  public var outdated: Bool

  @Attribute
  private var installedVersions: [String]
  @Attribute
  private var installedAsDependencyVersions: [String]

  @Attribute
  public private(set) var hasInstalledVersion: Bool
  @Attribute
  public private(set) var hasInstalledAsDependencyVersion: Bool

  @Attribute
  public private(set) var versionsStable: String?
  @Attribute
  public private(set) var versionsHead: String?

  @Attribute
  public private(set) var license: String?
  @Attribute
  public private(set) var homepage: String

  @Attribute
  public private(set) var baseName: String
  @Attribute
  public private(set) var tap: String
  @Attribute
  public private(set) var desc: String

  public init(info: InfoResponse) throws {
    identifier = info.identifier.description
//    sortValue = "\(info.identifier.name)--\(info.identifier.tap)"

    checksum = info.rubySourceChecksum.sha256

    outdated = info.outdated

    homepage = info.homepage
    baseName = info.identifier.name

    tap = info.identifier.tap

    desc = info.desc ?? ""

    versionsHead = info.versions.head?.description
    versionsStable = info.versions.stable?.description ?? info.versions.head?.description

    license = info.license

    lastUpdated = .now

    let infoInstalledVersions = Array(info.installedVersions)
    installedVersions = infoInstalledVersions
    hasInstalledVersion = !infoInstalledVersions.isEmpty

    let infoInstalledAsDependencyVersions = Array(info.installedAsDependencyVersions)
    installedAsDependencyVersions = infoInstalledAsDependencyVersions
    hasInstalledAsDependencyVersion = !infoInstalledAsDependencyVersions.isEmpty

//    let json = try encoder.encode(info.onlyRemote)
    let (json, hash) = try info.onlyRemote.stableHash()
    self.json = json
    self.stableHash = hash
  }

  public init(info: InfoResultOnlyRemote) throws {
    identifier = info.identifier.description
//    sortValue = "\(info.identifier.name)--\(info.identifier.tap)"

    checksum = info.rubySourceChecksum.sha256

    outdated = false

    homepage = info.homepage
    baseName = info.identifier.name

    tap = info.identifier.tap

    desc = info.desc ?? ""

    versionsHead = info.versions.head?.description
    versionsStable = info.versions.stable?.description ?? info.versions.head?.description

    license = info.license

    lastUpdated = .now

    installedVersions = []
    hasInstalledVersion = false
    installedAsDependencyVersions = []
    hasInstalledAsDependencyVersion = false

    let (json, hash) = try info.stableHash()
    self.json = json
    self.stableHash = hash
  }

  public func update(
    infoRemote info: InfoResultOnlyRemote
  ) throws {
    
    let newVersionsStable = info.versions.stable
    if versionsStable != newVersionsStable {
      versionsStable = newVersionsStable
    }

    let newVersionsHead = info.versions.head
    if versionsHead != newVersionsHead {
      versionsHead = newVersionsHead
    }

    if license != info.license {
      license = info.license
    }

    if homepage != info.homepage {
      homepage = info.homepage
    }

    if desc != info.desc ?? "" {
      desc = info.desc ?? ""
    }

    // only for local
//    if self.checksum != info.rubySourceChecksum.sha256 {
//      self.checksum = info.rubySourceChecksum.sha256
//    }

    guard self.hasChanges else {
      return
    }

    let (json, hash) = try info.stableHash()
    self.json = json
    self.stableHash = hash

    lastUpdated = .now
  }

  public func update(info: InfoResponse) throws {
    if outdated != info.outdated {
      outdated = info.outdated
    }

    let newInfoInstalledVersions = Array(info.installedVersions)
    if installedVersions != newInfoInstalledVersions {
      installedVersions = newInfoInstalledVersions
    }

    if hasInstalledVersion != !newInfoInstalledVersions.isEmpty {
      hasInstalledVersion = !newInfoInstalledVersions.isEmpty
    }

    let installedAsDependencyVersionsArray = Array(info.installedAsDependencyVersions)
    if installedAsDependencyVersions != installedAsDependencyVersionsArray {
      installedAsDependencyVersions = installedAsDependencyVersionsArray
    }

    if hasInstalledAsDependencyVersion != !installedAsDependencyVersionsArray.isEmpty {
      hasInstalledAsDependencyVersion = !installedAsDependencyVersionsArray.isEmpty
    }

    if self.checksum != info.rubySourceChecksum.sha256 {
      self.checksum = info.rubySourceChecksum.sha256
    }

    try update(infoRemote: info.onlyRemote)
  }
}

extension PackageCache: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(stableHash)
  }
}

public protocol PackageCachable {
  var identifier: PackageIdentifierString { get }
  var package: PackageCache! { get set }
  var lastUpdated: Date { get set }
}

extension PackageCache: Identifiable {
  public var id: PackageIdentifier {
    PackageIdentifier(tap: tap, name: baseName)
  }
}

extension PackageCache {
  public var versions: any Collection<Version> {
    installedVersions.map {
      Version(version: .init(stringLiteral: $0), isDependency: false)
    } + installedAsDependencyVersions.map {
      Version(version: .init(stringLiteral: $0), isDependency: true)
    }
  }
}

//public struct LocalState: OptionSet {
//
//  public let rawValue: Int
//
//  public static let installed    = LocalState(rawValue: 1 << 0)
//  public static let outdated  = LocalState(rawValue: 1 << 1)
//  public static let update   = LocalState(rawValue: 1 << 2)
//
//  public init(rawValue: Int) {
//    self.rawValue = rawValue
//  }
//}
