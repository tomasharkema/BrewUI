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
        let pred = #Predicate<PackageCache> {
            $0.identifier == package.description
        }
        var fd = FetchDescriptor<PackageCache>(predicate: pred)
        fd.fetchLimit = 1
        _items = Query(fd)
        self.package = package
    }

    var body: some View {
        if let item = items.first {
            ItemDetailItemView(package: .cached(item))

        } else {
            Text("Package not found...")
        }
    }
}

struct ItemDetailItemView: View {
    @Namespace var bottomID
    @Environment(\.dismiss) var dismiss
    let package: PackageInfo

    @EnvironmentObject var brewService: BrewService

    var body: some View {
        VStack {
            HStack {
                if let installedVersion = package.installedVersion {
                    Button("Uninstall \(installedVersion)") {
                        Task {
                            do {
                                try await Dependencies.shared().brewService.uninstall(name: package.identifier)
                            } catch {
                                print(error)
                            }
                        }
                    }
                    // .disabled(brewService.isUpdateRunning)
                    if package.outdated {
                        Button("Upgrade") {
                            Task {
                                do {
                                    try await Dependencies.shared().brewService.upgrade(name: package.identifier)

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
                                try await Dependencies.shared().brewService.install(name: package.identifier)
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
                Text(package.identifier.description).font(.title.monospaced())
                Text(package.versionsStable ?? "").font(.body)
            }

            Text(package.license ?? "").font(.body)
            Link(package.homepage, destination: URL(string: package.homepage)!)
        }
        .textSelection(.enabled)
        .sheet(item: $brewService.stream) { stream in
            VStack {
                if !stream.isStreamingDone {
                    Button("Cancel") {
                        Task {
                            await Dependencies.shared().brewService.stream?.cancel()
                            await Dependencies.shared().brewService.done()
                        }
                    }
                }
                ScrollViewReader { scroll in
                    ScrollView {
                        HStack {
                            Text(stream.attributed).textSelection(.enabled)
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
                            await Dependencies.shared().brewService.done()
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
