//
//  UpdateAllButton.swift
//  
//
//  Created by Tomas Harkema on 01/10/2023.
//

import SwiftUI
import BrewCore

struct UpdateAllButton: View {
    @EnvironmentObject
    private var update: BrewUpdateService

    init() {}

    var body: some View {
        Button(action: {
            Task {
                await update.update()
            }
        }) {
            if update.updating.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Label("Refresh", systemImage: "arrow.counterclockwise")
            }
        }
        .keyboardShortcut("r", modifiers: [.command])
        .disabled(update.updating.isLoading)
    }
}
