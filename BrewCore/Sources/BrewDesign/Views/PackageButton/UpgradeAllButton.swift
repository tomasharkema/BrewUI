//
//  UpgradeAllButton.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import BrewCore
import SwiftUI
import Inject

struct UpgradeAllButton: View {

    @Injected(\.brewUpdateService)
    private var updateService: BrewUpdateService

    init() {
    }

    var body: some View {
        Button(action: {
            Task {
                try await updateService.upgradeAll()
            }
        }) {
            Text("Upgrade All")
        }
        .keyboardShortcut("r", modifiers: [.command, .shift])
        .disabled(updateService.all.isLoading)
    }
}
