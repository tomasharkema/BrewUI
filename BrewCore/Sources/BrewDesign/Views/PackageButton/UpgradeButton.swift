//
//  UpgradeButton.swift
//  
//
//  Created by Tomas Harkema on 01/10/2023.
//

import SwiftUI
import BrewCore
import Processed
import BrewShared

struct UpgradeButton: View {

    let package: PackageInfo

    @EnvironmentObject
    private var update: BrewUpdateService

    init(package: PackageInfo) {
        self.package = package
    }

    var body: some View {
        Button("Upgrade to \(package.versionsStable ?? "")") {
            Task {
                try await update.upgrade(name: package.identifier)
            }
        }
        .keyboardShortcut("u", modifiers: [.command])
        .disabled(update.upgrading.isLoading)
    }
}
