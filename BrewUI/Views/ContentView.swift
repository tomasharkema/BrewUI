//
//  ContentView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 05/05/2023.
//

import SwiftUI

extension String: Identifiable {
  public var id: Int {
    hashValue
  }
}

extension ListResult: Identifiable {
  var id: Int {
    hashValue
  }
}

extension InfoResult: Identifiable {
  var id: Int {
    hashValue
  }
}

struct ItemDetailView: View {
  @Environment(\.dismiss) var dismiss
//  @State var stream: StreamOutput?
  @ObservedObject var brewService: BrewService = .shared

  @MainActor @State var stream: StreamStreaming?
  @State var done = false
  let item: InfoResult

  var body: some View {
    VStack {
      HStack {
        if let installed = item.installed.first {
          Button("Uninstall \(installed.version)") {
            Task {
              done = false
              defer {
                done = true
              }
              try await BrewService.shared.uninstall(name: item.name)
            }
          }
          if item.outdated {
            Button("Upgrade") {
              Task {
                done = false
                defer {
                  done = true
                }
                try await BrewService.shared.upgrade(name: item.name)
              }
            }
          }
        } else {
          Button("Install") {
            Task {
              done = false
              defer {
                done = true
              }
              try await BrewService.shared.install(name: item.name)
            }
          }
        }

        Button("Close") {
          dismiss()
        }
      }

      HStack(alignment: .firstTextBaseline) {
        Text(item.name).font(.title.monospaced())
        Text(item.versions.stable ?? "").font(.body)
      }

      Text(item.license ?? "").font(.body)
      Text(item.homepage).font(.body)
    }
    .textSelection(.enabled)
      .onReceive(brewService.$stream) {
        stream = $0
      }
      .sheet(item: $stream) { stream in
        VStack {
          //        if !stream.isStreamingDone {
          //          Button("Cancel") {
          //            self.stream = nil
          //            BrewService.shared.done()
          //          }
          //        }
          ScrollViewReader { scroll in
            ScrollView {
              Text(stream.stream.stream).textSelection(.enabled)
                .multilineTextAlignment(.leading)
                .font(.body.monospaced())
                .padding()
              Text(" ").tag("bottom")
            }
            .onReceive(brewService.$stream) { _ in
              scroll.scrollTo("bottom")
            }
          }
          if stream.stream.isStreamingDone, done {
            Button("Done") {
              self.stream = nil
              BrewService.shared.done()
            }
          } else {
            ProgressView().progressViewStyle(CircularProgressViewStyle())
          }
        }.padding()
          .frame(minWidth: 600, minHeight: 400)
      }
  }
}
