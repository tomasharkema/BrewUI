//
//  UninstallButton.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import BrewCore
import BrewShared
import Processed
import SwiftUI

struct UninstallButton: View {
    private let package: PackageInfo
    private let installedVersion: String

    @EnvironmentObject
    private var updateService: BrewUpdateService

    init(package: PackageInfo, installedVersion: String) {
        self.package = package
        self.installedVersion = installedVersion
    }

    var body: some View {
        Button("Uninstall \(installedVersion)") {
            Task {
                try await updateService.uninstall(name: package.identifier)
            }
        }
        .disabled(updateService.uninstalling.isLoading)
    }
}
