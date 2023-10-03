//
//  InfoResult.swift
//  BrewUI
//
//  Created by Tomas Harkema on 31/08/2023.
//

import Foundation
import MetaCodable
import SwiftData

@Codable
public struct InfoResult {
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

extension InfoResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        let encoder = JSONEncoder()
        encoder.outputFormatting.insert(.sortedKeys)
        if let json = try? encoder.encode(self) {
            hasher.combine(json)
        }
    }
}

public struct Checksum: Codable, Hashable {
    public let sha256: String
}

@Codable
public struct InstalledVersion: Hashable {
    public let version: String

    @CodedAt("installed_as_dependency")
    public let installedAsDependency: Bool
}

public struct Versions: Codable, Hashable {
    public let stable: String?
    public let head: String?
}

public struct PackageIdentifier: Hashable, CustomStringConvertible, Codable, Identifiable {
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

    public var id: Self {
        self
    }

    public var nameWithoutCore: String {
        if tap == Self.core {
            name
        } else {
            description
        }
    }

    public var description: String {
        "\(tap)/\(name)"
    }
}

extension ListResult: Identifiable {
    public var id: String {
        "\(name)-\(version)"
    }
}

extension InfoResult: Identifiable {
    public var id: PackageIdentifier {
        identifier
    }
}

@Codable
public struct InfoResultOnlyRemote {

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

    public var identifier: PackageIdentifier {
        PackageIdentifier(tap: tap, name: name)
    }
}

extension InfoResultOnlyRemote: Hashable {
    public func hash(into hasher: inout Hasher) {
        let encoder = JSONEncoder()
        encoder.outputFormatting.insert(.sortedKeys)
        if let json = try? encoder.encode(self) {
            hasher.combine(json)
        }
    }
}

extension InfoResult {
    public var onlyRemote: InfoResultOnlyRemote {
        .init(
            name: self.name,
            tap: self.tap,
            desc: self.desc,
            license: self.license,
            homepage: self.homepage,
            versions: self.versions,
            deprecated: self.deprecated,
            deprecationDate: self.deprecationDate,
            deprecationReason: self.deprecationReason,
            disabled: self.disabled,
            disableDate: self.disableDate,
            disableReason: self.disableReason
        )
    }
}

extension InfoResultOnlyRemote: Identifiable {
    public var id: PackageIdentifier {
        identifier
    }
}
