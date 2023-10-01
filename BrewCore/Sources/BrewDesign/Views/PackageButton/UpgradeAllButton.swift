//
//  UpgradeAllButton.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import SwiftUI
import BrewCore

struct UpgradeAllButton: View {
    @EnvironmentObject
    private var update: BrewUpdateService

    init() {} 

    var body: some View {
        Button(action: {
            Task {
                try await update.upgradeAll()
            }
        }) {
            Text("Upgrade All")
        }
        .keyboardShortcut("r", modifiers: [.command, .shift])
        .disabled(update.upgrading.isLoading)
    }
}
