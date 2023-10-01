//
//  UninstallButton.swift
//  
//
//  Created by Tomas Harkema on 01/10/2023.
//

import SwiftUI
import BrewCore
import Processed
import BrewShared

struct UninstallButton: View {

    let package: PackageInfo
    let installedVersion: String

    @EnvironmentObject
    private var update: BrewUpdateService

    init(package: PackageInfo, installedVersion: String) {
        self.package = package
        self.installedVersion = installedVersion
    }

    var body: some View {
        Button("Uninstall \(installedVersion)") {
            Task {
                try await update.uninstall(name: package.identifier)
            }
        }
        .disabled(update.uninstalling.isLoading)
    }
}
