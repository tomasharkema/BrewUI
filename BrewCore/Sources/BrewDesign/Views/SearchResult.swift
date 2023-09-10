//
//  SearchResult.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import BrewCore
import BrewShared
import SwiftUI

public struct SearchResult: View {
    @Binding private var selection: PackageIdentifier?
    @EnvironmentObject private var search: BrewSearchService

    public init(selection: Binding<PackageIdentifier?>) {
        _selection = selection
    }

    @ViewBuilder
    private func remoteSection() -> some View {
        switch search.queryRemoteResult {
        case .idle:
            let _ = print("idle!")

        case .loading:
            HStack {
                Text("Also looking remotely...").font(.body.monospaced())
                ProgressView()
                    .controlSize(.small)
            }

        case .error:
            Text("ERROR")

        case let .result(result):
            Section("Remote") {
                ForEach(result) { item in
                    remoteSection(item: item)
                }
            }
        }
    }

    @ViewBuilder
    private func remoteSection(item: Result<PackageInfo, any Error>) -> some View {
        switch item {
        case let .success(item):
            ItemView(package: item, showInstalled: true)

        case let .failure(error as StdErr):
            VStack {
                Text(error.out.out)
                    .font(.body.monospaced())
                Text(error.out.err)
                    .font(.body.monospaced())
                    .foregroundColor(.red)
            }

        case let .failure(error):
            Text("Error: \(error.localizedDescription)")
                .font(.body.monospaced())
                .foregroundColor(.red)
        }
    }

    @ViewBuilder
    private func localSection() -> some View {
        Section("Local") {
            switch search.queryResult {
            case .loading, .idle:
                HStack {
                    Text("Also looking remotely...").font(.body.monospaced())
                    ProgressView()
                        .controlSize(.small)
                }

            case .error:
                Text("ERROR")

            case let .result(result):
                ForEach(result) { item in
                    ItemView(package: .cached(item), showInstalled: true)
                }
            }
        }
    }

    public var body: some View {
        if case .idle = search.queryResult {
        } else {
            List {
                remoteSection()
                localSection()
            }
        }
    }
}

extension Result<PackageInfo, Error>: Identifiable where Success: Hashable {
    public var id: Int {
        switch self {
        case let .success(has):
            return has.hashValue
        case let .failure(err):
            return "\(err)".hashValue
        }
    }
}
