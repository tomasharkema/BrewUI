//
//  UpdatingStateView.swift
//
//
//  Created by Tomas Harkema on 02/10/2023.
//

import BrewCore
import Processed
import SwiftUI

struct UpdatingStateView: View {
    private let isStreamingDone: Bool
    private let updating: LoadableState<UpdateState>

    private let dismiss: () -> Void

    init(
        isStreamingDone: Bool,
        updating: LoadableState<UpdateState>,
        dismiss: @escaping () -> Void
    ) {
        self.isStreamingDone = isStreamingDone
        self.updating = updating
        self.dismiss = dismiss
    }

    var body: some View {
        HStack(spacing: 5) {
            if isStreamingDone {
                if updating.isDone {
                    Button("Done") {
                        dismiss()
                    }
                } else {
                    ProgressView()
                        .controlSize(.small)
                    switch updating.data {
                    case .none:
                        Text("Running brew update...")

                    case let .updated(result):
                        Text("Brew update succeeded: \(String(describing: result)), syncing...")

                    case .synced:
                        Text("Brew synced!")
                    }
                }
            } else {
                Text("Running brew command...")
                ProgressView()
                    .controlSize(.small)
            }
        }
    }
}
