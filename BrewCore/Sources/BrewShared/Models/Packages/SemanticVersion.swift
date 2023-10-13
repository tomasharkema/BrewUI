//
//  VersionOrRaw.swift
//
//
//  Created by Tomas Harkema on 13/10/2023.
//

import Foundation
import SwiftMacros
import SemVer

@AddAssociatedValueVariable
public enum SemanticVersion: Hashable {
  case semver(SemVer.Version, String?)
  case raw(String)
}

extension SemanticVersion: ExpressibleByStringLiteral {

  public init(stringLiteral value: String) {

    let regex = /(?<normal>\S*)_(?<extra>\S*)/

    if let fullMatch = value.wholeMatch(of: regex), let version = SemVer.Version(String(fullMatch.output.normal)) {

      let metadata = version.metadata + [String(fullMatch.output.extra)]

      self = .semver(SemVer.Version(
        major: version.major, minor: version.minor, patch: version.patch,
        prerelease: version.prerelease, metadata: metadata
      ), value)

      return
    }

    if let version = SemVer.Version(value) {
      let rawValue = version.description != value ? value : nil

      self = .semver(version, rawValue)

    } else {
      print("VERSION NOT SEMVER: \(value)")
      self = .raw(value)
    }
  }
}

extension SemanticVersion: CustomStringConvertible {

  public var description: String {
    switch self {
    case .semver(let semver, let raw):
      if let raw {
        return "\(semver.description) (\(raw))"
      }
      return semver.description

    case .raw(let raw):
      return "RAW \(raw)"
    }
  }
}

extension SemanticVersion: Comparable {

  public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    switch (lhs, rhs) {
    case let (.semver(lhs, _), .semver(rhs, _)):
      return lhs < rhs

    case (.semver, .raw):
      return true

    case (.raw, .semver):
      return false

    case let (.raw(lhs), .raw(rhs)):
      return lhs < rhs
    }
  }
}
