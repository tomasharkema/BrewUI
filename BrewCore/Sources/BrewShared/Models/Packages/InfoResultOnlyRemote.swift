//
//  InfoResultOnlyRemote.swift
//
//
//  Created by Tomas Harkema on 12/10/2023.
//

import MetaCodable

@Codable
public struct InfoResultOnlyRemote: Hashable, Equatable, Sendable {
  public let name: String
  public let tap: String
  public let desc: String?
  public let license: String?
  public let homepage: String
  public let versions: Versions

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

public extension InfoResponse {
  var onlyRemote: InfoResultOnlyRemote {
    .init(
      name: name,
      tap: tap,
      desc: desc,
      license: license,
      homepage: homepage,
      versions: versions,
      deprecated: deprecated,
      deprecationDate: deprecationDate,
      deprecationReason: deprecationReason,
      disabled: disabled,
      disableDate: disableDate,
      disableReason: disableReason,
      rubySourceChecksum: rubySourceChecksum
    )
  }
}

extension InfoResultOnlyRemote: Identifiable {
  public var id: PackageIdentifier {
    identifier
  }
}

extension InfoResultOnlyRemote: StableHashable { }
