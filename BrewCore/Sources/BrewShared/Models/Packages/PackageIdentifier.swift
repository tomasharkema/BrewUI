//
//  PackageIdentifier.swift
//
//
//  Created by Tomas Harkema on 12/10/2023.
//

public struct PackageIdentifier: Hashable, Codable, Sendable {
  static let empty = PackageIdentifier(tap: "", name: "")
  public static let core = "homebrew/core"

  public let tap: String
  public let name: String

  public init(tap: String, name: String) {
    self.tap = tap
    self.name = name
  }

  public init(raw: String) throws {
    if let res = raw.firstMatch(of: /(\S+)\/(\S+)/) {
      tap = String(res.output.1)
      name = String(res.output.2)
    } else {
      tap = Self.core
      name = raw
    }
  }

  public var nameWithoutCore: String {
    if tap == Self.core {
      name
    } else {
      description
    }
  }
}

extension PackageIdentifier: CustomStringConvertible {
  public var description: String {
    "\(tap)/\(name)"
  }
}

extension PackageIdentifier: Identifiable {
  public var id: Self {
    self
  }
}
