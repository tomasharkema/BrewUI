//
//  PackageInfo.swift
//
//
//  Created by Tomas Harkema on 02/09/2023.
//

import Foundation
import SwiftMacros

@AddAssociatedValueVariable
public enum PackageInfo: Hashable, Equatable {
    case remote(InfoResult)
    case cached(PackageCache)
}

extension PackageInfo: Identifiable {
    public var id: Int {
        hashValue
    }
}

public extension InfoResult {
    var installedVersion: String? {
        installed.first?.version
    }

    var installedAsDependency: Bool? {
        installed.first?.installedAsDependency
    }

//    var installedOther: String? {
//        #if DEBUG
//            dispatchPrecondition(condition: .notOnQueue(.main))
//        #endif
//        return (try? JSONEncoder().encode(installed)).flatMap { String(data: $0, encoding: .utf8)
//        }
//    }

    var versionsStable: String? {
        versions.stable
    }
}

public extension PackageInfo {
    var installedVersion: String? {
        switch self {
        case let .remote(remote):
            return remote.installedVersion

        case let .cached(cached):
            return cached.installedVersion
        }
    }

    var installedAsDependency: Bool? {
        switch self {
        case let .remote(remote):
            return remote.installedAsDependency

        case let .cached(cached):
            return cached.installedAsDependency
        }
    }

    var versionsStable: String? {
        switch self {
        case let .remote(remote):
            return remote.versionsStable

        case let .cached(cached):
            return cached.versionsStable
        }
    }

    var identifier: PackageIdentifier {
        get throws {
            switch self {
            case let .remote(remote):
                return remote.identifier

            case let .cached(cached):
                return try PackageIdentifier(raw: cached.identifier)
            }
        }
    }

    var outdated: Bool {
        switch self {
        case .remote:
            return false // cause not installed!

        case let .cached(pkg):
            return pkg.outdated
        }
    }

    var license: String? {
        switch self {
        case let .remote(remote):
            return remote.license

        case let .cached(cached):
            return cached.license
        }
    }

    var homepage: String {
        switch self {
        case let .remote(remote):
            return remote.homepage

        case let .cached(cached):
            return cached.homepage
        }
    }
}

extension PackageInfo {
    var remote: InfoResult? {
        switch self {
        case let .remote(remote):
            return remote

        case .cached:
            return nil
        }
    }

    var cached: PackageCache? {
        switch self {
        case let .cached(cached):
            return cached

        case .remote:
            return nil
        }
    }
}
