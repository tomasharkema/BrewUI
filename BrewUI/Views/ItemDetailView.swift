//
//  ItemDetailView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftUI

struct ItemDetailView: View {
  @Namespace var bottomID

  @Environment(\.dismiss) var dismiss
  @ObservedObject var brewService: BrewService = .shared
  let package: PackageIdentifier

  var body: some View {
    if let item = brewService.cacheAll[package] {
      VStack {
        HStack {
          if let installed = item.installed.first {
            Button("Uninstall \(installed.version)") {
              Task {
                do {
                  try await BrewService.shared.uninstall(name: item.full_name)
                } catch {
                  print(error)
                }
              }
            }
            // .disabled(brewService.isUpdateRunning)
            if item.outdated {
              Button("Upgrade") {
                Task {
                  do {
                    try await BrewService.shared.upgrade(name: item.full_name)

                  } catch {
                    print(error)
                  }
                }
              }
              // .disabled(brewService.isUpdateRunning)
            }
          } else {
            Button("Install") {
              Task {
                do {
                  try await BrewService.shared.install(name: item.full_name)
                } catch {
                  print(error)
                }
              }
            }
            // .disabled(brewService.isUpdateRunning)
          }

          Button("Close") {
            dismiss()
          }
        }

        HStack(alignment: .firstTextBaseline) {
          Text(item.full_name.rawValue).font(.title.monospaced())
          Text(item.versions.stable ?? "").font(.body)
        }

        Text(item.license ?? "").font(.body)
        Link(item.homepage, destination: URL(string: item.homepage)!)
      }
      .textSelection(.enabled)
      .sheet(item: $brewService.stream) { stream in
        VStack {
          if !stream.isStreamingDone {
            Button("Cancel") {
              BrewService.shared.stream?.cancel()
              Task {
                await BrewService.shared.done()
              }
            }
          }
          ScrollViewReader { scroll in
            ScrollView {
              HStack {
                Text(stream.stream).textSelection(.enabled)
                  .multilineTextAlignment(.leading)
                  .font(.body.monospaced())
                  .padding()
                Spacer()
              }
              Text("End")
                .tag(bottomID)
                .onReceive(brewService.$stream) { _ in
                  scroll.scrollTo(bottomID, anchor: .bottom)
                }
            }
            .frame(minWidth: 600, minHeight: 400)
          }
          if stream.isStreamingDone {
            Button("Done") {
              Task {
                await BrewService.shared.done()
              }
            }
          } else {
            ProgressView().progressViewStyle(CircularProgressViewStyle())
          }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
      }

    } else {
      Text("Package not found...")
    }
  }
}
