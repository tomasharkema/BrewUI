//
//  ModelContainer.swift
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

extension URL {
    public static var brewStorage: URL {
        get throws {
            let baseFolder = URL.applicationSupportDirectory
            let workingFolder = baseFolder.appending(path: "brewui")

            if !FileManager.default.fileExists(atPath: workingFolder.path) {
                try FileManager.default.createDirectory(at: workingFolder, withIntermediateDirectories: false)
            }

#if DEBUG
            let url = workingFolder.appending(path: "brewui_debug.store")
#else
            let url = workingFolder.appending(path: "brewui.store")
#endif

            return url
        }
    }
}