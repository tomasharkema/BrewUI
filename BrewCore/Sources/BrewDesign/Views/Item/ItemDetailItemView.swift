//
//  ItemDetailItemView.swift
//
//
//  Created by Tomas Harkema on 07/09/2023.
//

import SwiftUI
import BrewCore
import BrewShared

struct ItemDetailItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var brewService: BrewService
    @State private var stream: BrewStreaming?

    private let package: PackageInfo

    init(package: PackageInfo) {
        self.package = package
    }

    @ViewBuilder
    private func installButton() -> some View {
        Button("Install") {
            Task {
                do {
                    stream = try await brewService.install(name: package.identifier)
                } catch {
                    print(error)
                }
            }
        }
        // .disabled(brewService.isUpdateRunning)
    }

    @ViewBuilder
    private func uninstallButton(installedVersion: String) -> some View {
        Button("Uninstall \(installedVersion)") {
            Task {
                do {
                    stream = try await brewService.uninstall(name: package.identifier)
                } catch {
                    print(error)
                }
            }
        }
    }

    @ViewBuilder
    private func upgradeButton() -> some View {
        Button("Upgrade") {
            Task {
                do {
                    stream = try await brewService.upgrade(name: package.identifier)

                } catch {
                    print(error)
                }
            }
        }
    }

    @ViewBuilder
    private func packageManageButtons() -> some View {
        HStack {
            if let installedVersion = package.installedVersion {
                uninstallButton(installedVersion: installedVersion)
                if package.outdated {
                    upgradeButton()
                }
            } else {
                installButton()
            }
            Button("Close") {
                dismiss()
            }
        }
    }

    // MARK: - body

    var body: some View {
        VStack {
            packageManageButtons()

            HStack(alignment: .firstTextBaseline) {
                Text((try? package.identifier.description) ?? "")
                    .font(.title.monospaced())
                Text(package.versionsStable ?? "")
                    .font(.body)
            }

            Text(package.license ?? "").font(.body)
            Link(package.homepage, destination: URL(string: package.homepage)!)
        }
        .textSelection(.enabled)
        .sheet(item: $stream) {
            StreamingView(stream: $0) {
                self.stream = nil
            }
        }
    }
}
