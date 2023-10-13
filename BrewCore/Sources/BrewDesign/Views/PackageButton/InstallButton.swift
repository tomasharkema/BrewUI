//
//  InstallButton.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import BrewCore
import BrewShared
import Processed
import SwiftUI

struct InstallButton: View {
  private let package: PackageInfo

  @EnvironmentObject
  private var updateService: BrewUpdateService

  init(package: PackageInfo) {
    self.package = package
  }

  var body: some View {
    Button("Install") {
      Task {
        try await updateService.install(name: package.identifier)
      }
    }
    .keyboardShortcut("i", modifiers: [.command])
    .disabled(updateService.installing.isLoading)
  }
}
