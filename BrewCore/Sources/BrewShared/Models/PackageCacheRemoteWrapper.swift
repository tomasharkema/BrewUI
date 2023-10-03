//
//  PackageCacheRemoteWrapper.swift
//
//
//  Created by Tomas Harkema on 02/10/2023.
//

import Foundation

public struct PackageCacheRemoteWrapper: Hashable, Identifiable {
    public let package: PackageCache
    
    public init(package: PackageCache) {
        self.package = package
    }

    public var id: PackageIdentifier {
        package.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(package.jsonRemote)
    }
}
