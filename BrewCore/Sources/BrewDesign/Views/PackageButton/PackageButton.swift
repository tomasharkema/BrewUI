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
import SwiftMacros
import SwiftUI
import Processed

public struct PackageButton: View {

    @AddAssociatedValueVariable
    public enum ButtonType {
        case updateAll
        case upgradeAll
        case package(PackageInfo)
    }

    private let type: ButtonType

    @EnvironmentObject
    private var update: BrewUpdateService

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
                    UninstallButton(package: package, installedVersion: installedVersion)
                    if package.outdated {
                        UpgradeButton(package: package)
                    }
                } else {
                    InstallButton(package: package)
                }
            }
        }
        .disabled(update.isAnyLoading)
    }
}
