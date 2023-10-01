//
//  InstallButton.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import SwiftUI
import BrewCore
import Processed
import BrewShared

struct InstallButton: View {

    let package: PackageInfo

    @EnvironmentObject
    private var update: BrewUpdateService

    init(package: PackageInfo) {
        self.package = package
    }

    var body: some View {
        Button("Install") {
            Task {
                try await update.install(name: package.identifier)
            }
        }
        .keyboardShortcut("i", modifiers: [.command])
        .disabled(update.installing.isLoading)
    }
}
