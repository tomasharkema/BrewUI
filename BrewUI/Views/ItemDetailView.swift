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
    @Environment(\.dismiss) var dismiss
    let package: PackageInfo

    @State var stream: BrewStreaming?

    var body: some View {
        VStack {
            HStack {
                if let installedVersion = package.installedVersion {
                    Button("Uninstall \(installedVersion)") {
                        Task {
                            do {
                                stream = try await Dependencies.shared().brewService.uninstall(name: package.identifier)
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
                                    stream = try await Dependencies.shared().brewService.upgrade(name: package.identifier)

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
                                stream = try await Dependencies.shared().brewService.install(name: package.identifier)
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
        .sheet(item: $stream) {
            StreamingView(stream: $0) {
                self.stream = nil
            }
        }
    }
}

struct StreamingView: View {
    @Namespace private var bottomID
    @ObservedObject private var stream: BrewStreaming

    private let dismiss: () -> ()

    init(stream: BrewStreaming, dismiss: @escaping () -> ()) {
        self.stream = stream
        self.dismiss = dismiss
    }

    var body: some View {
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
                    Text("End")
                        .tag(bottomID)
                        .onReceive(stream.$stream) { _ in
                                scroll.scrollTo(bottomID, anchor: .bottom)
                            }
                }
                .frame(minWidth: 600, minHeight: 400)
            }
            if stream.stream.isStreamingDone {
                Button("Done") {
                    dismiss()

//                        Task {
//                            await Dependencies.shared().brewService.done()
//                        }
                }
            } else {
                ProgressView().progressViewStyle(CircularProgressViewStyle())
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }
}
