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
import Inject

public struct PackageButton: View {
    private let type: ButtonType

    @Injected(\.brewUpdateService)
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
                if let installedVersion = package.installedVersion {
                    UninstallButton(
                        package: package,
                        installedVersion: installedVersion
                    ).disabled(package.installedAsDependency)
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
