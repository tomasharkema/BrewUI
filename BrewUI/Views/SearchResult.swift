//
//  SearchResult.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import SwiftUI
import BrewCore

struct SearchResult: View {
    @Binding var selection: PackageIdentifier?
    @EnvironmentObject var search: BrewSearchService

    var body: some View {
        if let queryResult = search.queryResult {
            List {
                if !(search.queryRemoteResult?.isEmpty ?? false) {
                    Section("Remote") {
                        if let queryRemoteResult = search.queryRemoteResult {
                            ForEach(queryRemoteResult) { item in
                                switch item {
                                case .success(let item):
                                    ItemView(package: item, showInstalled: true)
                                case .failure(let error as StdErr):
                                    Text(error.message)
                                        .font(.body.monospaced())
                                        .foregroundColor(.red)
                                case .failure(let error):
                                    Text("Error: \(error.localizedDescription)")
                                        .font(.body.monospaced())
                                        .foregroundColor(.red)
                                }
                            }
                        } else {
                            HStack {
                                Text("Also looking remotely...").font(.body.monospaced())
                                ProgressView()
                            }
                        }
                    }
                }
                Section("Local") {
                    ForEach(queryResult) { item in
                        ItemView(package: .cached(item), showInstalled: true)
                    }
                }
            }
            .tag(TabViewSelection.searchResult)
            .tabItem {
                Text("Search")
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
