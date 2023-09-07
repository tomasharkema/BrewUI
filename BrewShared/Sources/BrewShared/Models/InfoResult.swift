//
//  InfoResult.swift
//  BrewUI
//
//  Created by Tomas Harkema on 31/08/2023.
//


import Foundation
import SwiftData

struct ListResult: Hashable {
    let name: String
    let version: String
    //  let cask: Bool
}

// swiftlint:disable identifier_name

public struct InfoResult: Codable, Hashable, Equatable {
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
    public let deprecation_date: String?
    public let deprecation_reason: String?
    public let disabled: Bool
    public let disable_date: String?
    public let disable_reason: String?
    //  let service: String?

    public let ruby_source_checksum: Checksum

    public var identifier: PackageIdentifier {
        PackageIdentifier(tap: tap, name: name)
    }
}


public struct Checksum: Codable, Hashable {
    public let sha256: String
}

public struct InstalledVersion: Codable, Hashable {
    public let version: String
    public let installed_as_dependency: Bool
}

// swiftlint:enable identifier_name

public struct Versions: Codable, Hashable {
    public let stable: String?
    public let head: String?
}

public struct PackageIdentifier: Hashable, CustomStringConvertible, Codable, Identifiable {
    static let empty = PackageIdentifier(tap: "", name: "")
    private static let core = "homebrew/core"

    public let tap: String
    public let name: String

    public init(tap: String, name: String) {
        self.tap = tap
        self.name = name
    }

    private static let rawRegex = /(.+)\/(.+)/

    public init(raw: String) throws {
        if let res = try Self.rawRegex.firstMatch(in: raw) {
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
            return name
        } else {
            return description
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
