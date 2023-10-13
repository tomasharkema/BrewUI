//
//  UpgradeButton.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import BrewCore
import BrewShared
import Processed
import SwiftUI

struct UpgradeButton: View {
  private let package: PackageInfo

  @EnvironmentObject
  private var updateService: BrewUpdateService

  init(package: PackageInfo) {
    self.package = package
  }

  var body: some View {
    Button("Upgrade to \(package.versionsStable?.description ?? "")") {
      Task {
        try await updateService.upgrade(name: package.identifier)
      }
    }
    .keyboardShortcut("u", modifiers: [.command])
    .disabled(updateService.upgrading.isLoading)
  }
}
