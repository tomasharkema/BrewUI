//
//  PackageButton.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import BrewCore
import BrewShared
import SwiftUI

public struct PackageButton: View {
  private let type: ButtonType

  @EnvironmentObject
  private var updateService: BrewUpdateService

  public init(type: ButtonType) {
    self.type = type
  }

  public var body: some View {
    HStack {
      switch type {
      case .upgradeAll:
        UpgradeAllButton()

      case .updateAll:
        UpdateAllButton()

      case let .package(package):
        if let anyVersion = package.versions?.first {
          UninstallButton(
            package: package,
            installedVersion: anyVersion
          ).disabled(package.firstInstalledAsDependency != nil)
          
          if package.outdated {
            UpgradeButton(package: package)
          }
        } else {
          InstallButton(package: package)
        }
      }
    }
    .disabled(updateService.isAnyLoading)
  }
}
