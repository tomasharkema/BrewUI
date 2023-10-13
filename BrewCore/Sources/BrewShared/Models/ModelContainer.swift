//
//  ModelContainer.swift
//
//
//  Created by Tomas Harkema on 04/09/2023.
//

import Foundation

public extension URL {
  static var brewStorage: URL {
    get throws {
      let baseFolder = URL.applicationSupportDirectory
      let workingFolder = baseFolder.appending(path: "brewui")

      if !FileManager.default.fileExists(atPath: workingFolder.path) {
        try FileManager.default.createDirectory(
          at: workingFolder,
          withIntermediateDirectories: false
        )
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
