//
//  PackageInfo.swift
//
//
//  Created by Tomas Harkema on 02/09/2023.
//

import Foundation
import ExtractCaseValue

@ExtractCaseValue<InfoResult?>(name: "remote", kind: .firstMatchingType)
@ExtractCaseValue<PackageCache?>(name: "cached", kind: .firstMatchingType)
public enum PackageInfo: Hashable {
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
        (try? JSONEncoder().encode(installed)).flatMap { String(data: $0, encoding: .utf8) }
    }

    public var versionsStable: String? {
        versions.stable
    }
}

extension PackageInfo {
    public var installedVersion: String? {
        remote?.installedVersion ?? cached?.installedVersion
    }
    public var installedAsDependency: Bool? {
        remote?.installedAsDependency ?? cached?.installedAsDependency
    }

    public var versionsStable: String? {
        remote?.versionsStable ?? cached?.versionsStable
    }

    public var identifier: PackageIdentifier {
        remote?.identifier ?? (try! PackageIdentifier(raw: cached!.identifier))
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
        remote?.license ?? cached?.license
    }

    public var homepage: String {
        remote?.homepage ?? cached!.homepage
    }
}
