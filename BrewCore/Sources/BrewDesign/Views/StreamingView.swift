//
//  StreamingView.swift
//
//
//  Created by Tomas Harkema on 07/09/2023.
//

import BrewCore
import SwiftUI

public struct StreamingView: View {
    @Namespace private var bottomID
    @ObservedObject private var stream: BrewStreaming

    private let dismiss: () -> Void

    public init(stream: BrewStreaming, dismiss: @escaping () -> Void) {
        self.stream = stream
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
                        Text(stream.stream.attributed).textSelection(.enabled)
                            .multilineTextAlignment(.leading)
                            .font(.body.monospaced())
                            .padding()
                        Spacer()
                    }
                    Spacer()
                        .tag(bottomID)
                }
                .frame(minWidth: 600, minHeight: 400)
                .onReceive(stream.$stream) { _ in
                    scroll.scrollTo(bottomID, anchor: .bottom)
                }
            }
            if stream.stream.isStreamingDone {
                Button("Done") {
                    dismiss()

                    //                        Task {
                    //                            await Dependencies.shared().brewService.done()
                    //                        }
                }
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }
}
