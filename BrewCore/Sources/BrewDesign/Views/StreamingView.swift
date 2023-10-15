//
//  StreamingView.swift
//
//
//  Created by Tomas Harkema on 07/09/2023.
//

import BrewCore
import BrewShared
import SwiftUI

public struct StreamingView: View {
  @Namespace
  private var bottomID

  @EnvironmentObject
  private var brewService: BrewService

  @EnvironmentObject
  private var updateService: BrewUpdateService

  @StateObject
  private var stream: BrewStreaming

  private let dismiss: () -> Void

  public init(
    stream: BrewStreaming,
//        updateService: BrewUpdateService,
    dismiss: @escaping () -> Void
  ) {
    _stream = StateObject(wrappedValue: stream)
//        self.updateService = updateService
    self.dismiss = dismiss
  }

  public var body: some View {
    VStack {
      if !stream.stream.isStreamingDone {
        Button("Cancel") {
          Task {
            stream.stream.cancel()
            dismiss()
          }
        }
      }
      ScrollViewReader { scroll in
        ScrollView {
          HStack {
            Text(stream.stream.attributed)
              .textSelection(.enabled)
              .multilineTextAlignment(.leading)
              .font(.body.monospaced())
              .padding()
            Spacer()
          }
          Spacer()
            .id(bottomID)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onReceive(stream.$stream) { _ in
          withAnimation {
            scroll.scrollTo(bottomID, anchor: .bottom)
          }
        }
      }

      UpdatingStateView(
        isStreamingDone: stream.stream.isStreamingDone,
        updating: updateService.updating
      ) {
        dismiss()
      }
    }
    .padding()
    .frame(minWidth: 600, minHeight: 400)
  }
}

extension UpdateState: CustomStringConvertible {
  public var description: String {
    switch self {
    case .updated:
      "updated"

    case .initialSynced:
      "initialSynced"

    case .initialSyncing:
      "initialSyncing"

    case .synced:
      "synced"
    }
  }
}
