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
    case tap
    case tapInfo(String)

    var command: String {
        switch self {
        case let .info(info):
            info.command
        case let .install(pkg):
            "install \(pkg.nameWithoutCore)"
        case let .uninstall(pkg):
            "uninstall \(pkg.nameWithoutCore)"
        case let .upgrade(upgrade):
            upgrade.command
        case .update:
            "update"
        case let .search(query):
            "search --formula \(query)"
        case let .list(list):
            list.command
        case .tap:
            "tap"
        case .tapInfo(let name):
            "tap-info \(name) --json"
        }
    }
}

extension BrewCommand {
    enum InfoCommand: CommandString {
        case installed
        case formula(PackageIdentifier)

        var commandPartial: String {
            switch self {
            case .installed:
                "--json=v1 --installed"

            case let .formula(pkg):
                "--json=v1 --formula \(pkg.nameWithoutCore)"
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
                "upgrade"
            case let .package(pkg):
                "upgrade \(pkg.nameWithoutCore)"
            }
        }
    }

    enum ListCommand: CommandString {
        case versions

        var command: String {
            switch self {
            case .versions:
                "list --versions"
            }
        }
    }
}
