//
//  File.swift
//  
//
//  Created by Tomas Harkema on 04/09/2023.
//

import Foundation
import SwiftData

extension ModelContainer {
    public static func brew(url: URL) throws -> ModelContainer {
        try ModelContainer(
            for: PackageCache.self, InstalledCache.self, OutdatedCache.self, UpdateCache.self,
            configurations: ModelConfiguration(url: url)
        )
    }
}
