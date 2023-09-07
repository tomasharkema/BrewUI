//
//  SearchResult.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import SwiftUI
import BrewCore
import BrewShared

public struct SearchResult: View {
    @Binding private var selection: PackageIdentifier?
    @EnvironmentObject private var search: BrewSearchService

    public init(selection: Binding<PackageIdentifier?>) {
        self._selection = selection
    }

    @ViewBuilder
    private func remoteSection() -> some View {
        switch search.queryRemoteResult {
        case .idle:
            EmptyView()

        case .loading:
            HStack {
                Text("Also looking remotely...").font(.body.monospaced())
                ProgressView()
            }

        case .error:
            Text("ERROR")

        case .result(let result):
            Section("Remote") {
                ForEach(result) { item in
                    remoteSection(item: item)
                }
            }
        }
    }

    @ViewBuilder
    private func remoteSection(item: Result<PackageInfo, Error>) -> some View {
        switch item {
        case .success(let item):
            ItemView(package: item, showInstalled: true)

        case .failure(let error as StdErr):
            VStack {
                Text(error.stdout)
                    .font(.body.monospaced())
                Text(error.stderr)
                    .font(.body.monospaced())
                    .foregroundColor(.red)
            }

        case .failure(let error):
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
                }

            case .error:
                Text("ERROR")

            case .result(let result):
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
        case .success(let has):
            return has.hashValue
        case .failure(let err):
            return "\(err)".hashValue
        }
    }
}
