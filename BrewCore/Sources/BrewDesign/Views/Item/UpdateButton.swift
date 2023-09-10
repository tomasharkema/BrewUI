//
//  UpdateButton.swift
//  
//
//  Created by Tomas Harkema on 10/09/2023.
//

import Foundation
import SwiftUI
import BrewCore
import BrewShared
import OSLog
import SwiftMacros

public struct UpdateButton: View {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UpdateButton")

    @EnvironmentObject private var brewService: BrewService

    private let type: ButtonType
    @Binding private var state: LoadingState

    @State private var stream: BrewStreaming?

    public init(type: ButtonType, state: Binding<LoadingState>) {
        self.type = type
        self._state = state
    }

    private func executeTask(_ handler: @escaping () async throws -> BrewStreaming) {
        Task {
            state = .executing
            do {
                self.stream = try await handler()
                state = .updating
                try await brewService.update()
                state = .idle
            } catch {
                Self.logger.error("got error: \(error)")
                state = .error(error)
            }
        }
    }

    @ViewBuilder
    private func installButton(package: PackageInfo) -> some View {
        Button("Install") {
            executeTask {
                try await brewService.install(name: package.identifier)
            }
        }
    }

    @ViewBuilder
    private func uninstallButton(installedVersion: String, package: PackageInfo) -> some View {
        Button("Uninstall \(installedVersion)") {
            executeTask {
                try await brewService.uninstall(name: package.identifier)
            }
        }
    }

    @ViewBuilder
    private func upgradeButton(package: PackageInfo) -> some View {
        Button("Upgrade") {
            executeTask {
                try await brewService.upgrade(name: package.identifier)
            }
        }
    }

    @ViewBuilder
    private func upgradeAll() -> some View {
        Button(action: {
            executeTask {
                try await brewService.upgrade()
            }
        }) {
            Text("Upgrade All")
        }
    }

    @ViewBuilder
    private func updateAll() -> some View {
        Button(action: {
            Task {
                try await brewService.update()
            }
        }) {
            if brewService.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Label("Refresh", systemImage: "arrow.counterclockwise")
            }
        }
    }

    public var body: some View {
        Group {
            switch type {
            case .upgradeAll:
                upgradeAll()

            case .updateAll:
                updateAll()

            case .package(let package):
                if let installedVersion = package.installedVersion {
                    uninstallButton(installedVersion: installedVersion, package: package)
                    if package.outdated {
                        upgradeButton(package: package)
                    }
                } else {
                    installButton(package: package)
                }
            }
        }
        .disabled(brewService.isLoading)
        .sheet(item: $stream) {
            StreamingView(stream: $0) {
                stream = nil
            }
        }
    }
}

extension UpdateButton {
    @AddAssociatedValueVariable
    public enum ButtonType {
        case updateAll
        case upgradeAll
        case package(PackageInfo)
    }

    @AddAssociatedValueVariable
    public enum LoadingState {
        case idle
        case executing
        case updating
        case error(any Error)

//        public var error: (any Error)? {
//            switch self {
//            case .error(let error):
//                return error
//            default:
//                return nil
//            }
//        }
    }
}
