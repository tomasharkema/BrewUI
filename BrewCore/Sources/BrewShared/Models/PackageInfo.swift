//
//  PackageInfo.swift
//
//
//  Created by Tomas Harkema on 02/09/2023.
//

import Foundation

public enum PackageInfo: Hashable, Equatable {
    case remote(InfoResult)
    case cached(PackageCache)
}

extension PackageInfo: Identifiable {
    public var id: Int {
        hashValue
    }
}

extension InfoResult {
    public var installedVersion: String? {
        installed.first?.version
    }

    public var installedAsDependency: Bool? {
        installed.first?.installed_as_dependency
    }

    public var installedOther: String? {
#if DEBUG
        dispatchPrecondition(condition: .notOnQueue(.main))
#endif
        return (try? JSONEncoder().encode(installed)).flatMap { String(data: $0, encoding: .utf8) }
    }

    public var versionsStable: String? {
        versions.stable
    }
}

extension PackageInfo {
    public var installedVersion: String? {
        switch self {
        case .remote(let remote):
            return remote.installedVersion

        case .cached(let cached):
            return cached.installedVersion
        }
    }

    public var installedAsDependency: Bool? {
        switch self {
        case .remote(let remote):
            return remote.installedAsDependency

        case .cached(let cached):
            return cached.installedAsDependency
        }
    }

    public var versionsStable: String? {
        switch self {
        case .remote(let remote):
            return remote.versionsStable

        case .cached(let cached):
            return cached.versionsStable
        }
    }

    public var identifier: PackageIdentifier {
        get throws {
            switch self {
            case .remote(let remote):
                return remote.identifier

            case .cached(let cached):
                return try PackageIdentifier(raw: cached.identifier)
            }
        }
    }

    public var outdated: Bool {
        switch self {
        case .remote:
            return false // cause not installed!

        case .cached(let pkg):
            return pkg.outdated
        }
    }

    public var license: String? {
        switch self {
        case .remote(let remote):
            return remote.license

        case .cached(let cached):
            return cached.license
        }
    }

    public var homepage: String {
        switch self {
        case .remote(let remote):
            return remote.homepage

        case .cached(let cached):
            return cached.homepage
        }
    }
}

extension PackageInfo {
    var remote: InfoResult? {
        switch self {
        case .remote(let remote):
            return remote
        default:
            return nil
        }
    }
    
    var cached: PackageCache? {
        switch self {
        case .cached(let cached):
            return cached
        default:
            return nil
        }
    }
}
