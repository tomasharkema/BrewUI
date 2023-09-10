//
//  ItemDetailItemView.swift
//
//
//  Created by Tomas Harkema on 07/09/2023.
//

import BrewCore
import BrewShared
import SwiftUI

struct ItemDetailItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var brewService: BrewService

    @State
    private var updatingState: UpdateButton.LoadingState = .idle

    private let package: PackageInfo

    init(package: PackageInfo) {
        self.package = package
    }

    // MARK: - body

    var body: some View {
        VStack {
            HStack {
                UpdateButton(type: .package(package), state: $updatingState)
                Button("Close") {
                    dismiss()
                }
            }
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
    }
}
