//
//  InfoResult.swift
//  BrewUI
//
//  Created by Tomas Harkema on 31/08/2023.
//

import MetaCodable

@Codable
public struct InfoResponse: Hashable, Sendable {
  public let name: String
  public let tap: String
  public let desc: String?
  public let license: String?
  public let homepage: String
  public let installed: [InstalledVersion]
  public let versions: Versions

  public let pinned: Bool
  public let outdated: Bool
  public let deprecated: Bool

  @CodedAt("deprecation_date")
  public let deprecationDate: String?

  @CodedAt("deprecation_reason")
  public let deprecationReason: String?

  public let disabled: Bool

  @CodedAt("disable_date")
  public let disableDate: String?

  @CodedAt("disable_reason")
  public let disableReason: String?

  @CodedAt("ruby_source_checksum")
  public let rubySourceChecksum: Checksum

  public var identifier: PackageIdentifier {
    PackageIdentifier(tap: tap, name: name)
  }
}

extension InfoResponse: Identifiable {
  public var id: PackageIdentifier {
    identifier
  }
}

extension InfoResponse {
  public var installedVersions: any Sequence<String> {
    installed.filter {
      !$0.installedAsDependency
    }.map(\.version)
  }

  public var firstInstalledVersion: String? {
    Array(installedVersions).first
  }

  public var installedAsDependencyVersions: any Sequence<String> {
    installed.filter {
      $0.installedAsDependency
    }.map(\.version)
  }

  //    var installedOther: String? {
  //        #if DEBUG
  //            dispatchPrecondition(condition: .notOnQueue(.main))
  //        #endif
  //        return (try? JSONEncoder().encode(installed)).flatMap { String(data: $0, encoding:
  //        .utf8)
  //        }
  //    }

  var versionsStable: String? {
    versions.stable
  }
}
