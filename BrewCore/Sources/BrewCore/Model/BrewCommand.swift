//
//  BrewCommand.swift
//
//
//  Created by Tomas Harkema on 11/09/2023.
//

import BrewShared
import Foundation

protocol CommandString {
    var command: String { get }
}

enum BrewCommand: CommandString {
    case info(InfoCommand)
    case install(PackageIdentifier)
    case uninstall(PackageIdentifier)
    case upgrade(UpgradeCommand)
    case update
    case search(String)
    case list(ListCommand)

    var command: String {
        switch self {
        case let .info(info):
            return info.command
        case let .install(pkg):
            return "install \(pkg.nameWithoutCore)"
        case let .uninstall(pkg):
            return "uninstall \(pkg.nameWithoutCore)"
        case let .upgrade(upgrade):
            return upgrade.command
        case .update:
            return "update"
        case let .search(query):
            return "search --formula \(query)"
        case let .list(list):
            return list.command
        }
    }
}

enum InfoCommand: CommandString {
    case installed
    case formula(PackageIdentifier)

    var commandPartial: String {
        switch self {
        case .installed:
            return "--json=v1 --installed"

        case let .formula(pkg):
            return "--json=v1 --formula \(pkg.nameWithoutCore)"
        }
    }

    var command: String {
        "info \(commandPartial)"
    }
}

enum UpgradeCommand: CommandString {
    case all
    case package(PackageIdentifier)

    var command: String {
        switch self {
        case .all:
            return "upgrade"
        case let .package(pkg):
            return "upgrade \(pkg.nameWithoutCore)"
        }
    }
}

enum ListCommand: CommandString {
    case versions

    var command: String {
        switch self {
        case .versions:
            return "list --versions"
        }
    }
}
