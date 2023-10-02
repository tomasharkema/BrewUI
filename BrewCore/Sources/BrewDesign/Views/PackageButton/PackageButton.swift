//
//  PackageButton.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import BrewCore
import BrewShared
import Foundation
import OSLog
import Processed
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
                UpgradeAllButton(updateService: updateService)

            case .updateAll:
                UpdateAllButton(updateService: updateService)

            case let .package(package):
                if let installedVersion = package.installedVersion {
                    UninstallButton(
                        package: package,
                        installedVersion: installedVersion,
                        updateService: updateService
                    )
                    if package.outdated {
                        UpgradeButton(package: package, updateService: updateService)
                    }
                } else {
                    InstallButton(package: package, updateService: updateService)
                }
            }
        }
        .disabled(updateService.isAnyLoading)
    }
}
