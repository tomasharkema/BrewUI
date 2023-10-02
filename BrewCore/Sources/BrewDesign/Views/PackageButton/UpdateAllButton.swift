//
//  UpdateAllButton.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import BrewCore
import SwiftUI

struct UpdateAllButton: View {
    private let updateService: BrewUpdateService

    init(updateService: BrewUpdateService) {
        self.updateService = updateService
    }

    var body: some View {
        Button(action: {
            Task {
                await updateService.update()
            }
        }) {
            Text("STATE: \(String(describing: updateService.updatingAll))")
            if updateService.updatingAll.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Label("Refresh", systemImage: "arrow.counterclockwise")
            }
        }
        .keyboardShortcut("r", modifiers: [.command])
        .disabled(updateService.updatingAll.isLoading)
    }
}
