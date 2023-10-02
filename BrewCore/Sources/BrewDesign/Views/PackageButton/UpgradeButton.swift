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
    private let updateService: BrewUpdateService

    init(package: PackageInfo, updateService: BrewUpdateService) {
        self.package = package
        self.updateService = updateService
    }

    var body: some View {
        Button("Upgrade to \(package.versionsStable ?? "")") {
            Task {
                try await updateService.upgrade(name: package.identifier)
            }
        }
        .keyboardShortcut("u", modifiers: [.command])
        .disabled(updateService.upgrading.isLoading)
    }
}
