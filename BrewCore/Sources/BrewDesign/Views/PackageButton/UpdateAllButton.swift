//
//  UpdateAllButton.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import BrewCore

import SwiftUI

struct UpdateAllButton: View {
  @EnvironmentObject
  private var updateService: BrewUpdateService

  init() {}

  var body: some View {
    Button(action: {
      Task {
        await updateService.update()
      }
    }) {
      if updateService.all.isLoading {
        ProgressView()
          .controlSize(.small)
      } else {
        Label("Refresh", systemImage: "arrow.counterclockwise")
      }
    }
    .keyboardShortcut("r", modifiers: [.command])
    .disabled(updateService.all.isLoading)
  }
}
