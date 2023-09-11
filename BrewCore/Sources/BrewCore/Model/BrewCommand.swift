//
//  BrewCommand.swift
//
//
//  Created by Tomas Harkema on 11/09/2023.
//

import Foundation
import BrewShared

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
        case .info(let info):
            return info.command
        case .install(let pkg):
            return "install \(pkg.nameWithoutCore)"
        case .uninstall(let pkg):
            return "uninstall \(pkg.nameWithoutCore)"
        case .upgrade(let upgrade):
            return upgrade.command
        case .update:
            return "update"
        case .search(let query):
            return "search --formula \(query)"
        case .list(let list):
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

        case .formula(let pkg):
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
        case .package(let pkg):
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
