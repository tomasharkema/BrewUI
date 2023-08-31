//
//  ItemDetailView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftData
import SwiftUI
import BrewCore

struct ItemDetailView: View {
    //  @Namespace var bottomID
    //  @Environment(\.dismiss) var dismiss
    let package: PackageIdentifier

    @Query
    var items: [PackageCache]

    init(package: PackageIdentifier) {
        _items = Query(filter: #Predicate<PackageCache> { $0.name == package.rawValue })
        self.package = package
    }

    var body: some View {
        if let item = items.first?.result {
            ItemDetailItemView(item: item)

        } else {
            Text("Package not found...")
        }
    }
}

struct ItemDetailItemView: View {
    @Namespace var bottomID
    @Environment(\.dismiss) var dismiss
    let item: InfoResult

    @ObservedObject var brewService = BrewService.shared

    var body: some View {
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
                            .onReceive(BrewService.shared.$stream) { _ in
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
    }
}
