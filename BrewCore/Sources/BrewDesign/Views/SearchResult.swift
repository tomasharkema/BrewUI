//
//  SearchResult.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import BrewCore
import BrewShared
import Inject
import SwiftUI

public struct SearchResultView: View {
  @Binding
  private var selection: PackageIdentifier?

  @Injected(\.brewSearchService)
  private var search: BrewSearchService

  public init(selection: Binding<PackageIdentifier?>) {
    _selection = selection
  }

  @ViewBuilder @MainActor
  private func remoteSection() -> some View {
    switch search.queryRemoteResult {
    case .absent:
      EmptyView()
    case .loading:
      HStack {
        Text("Also looking remotely...").font(.body.monospaced())
        ProgressView()
          .controlSize(.small)
      }

    case let .error(error):
      Text("ERROR \(error.localizedDescription)")

    case let .loaded(result):
      if !result.isEmpty {
        Section("Remote") {
          ForEach(result) { item in
            remoteSection(item: item)
          }
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
        Text(error.out.attributed)
          .font(.body.monospaced())
          .foregroundColor(.red)
      }

    case let .failure(error):
      Text("Error: \(error.localizedDescription)")
        .font(.body.monospaced())
        .foregroundColor(.red)
    }
  }

  @ViewBuilder @MainActor
  private func localSection() -> some View {
    Section("Local") {
      switch search.queryResult {
      case .loading, .absent:
        HStack {
          ProgressView()
            .controlSize(.small)
        }

      case let .error(error):
        Text("ERROR \(error.localizedDescription)")

      case let .loaded(result):
        ForEach(result) { item in
          ItemView(package: .cached(item), showInstalled: true)
        }
      }
    }
  }

  public var body: some View {
    if !search.queryResult.isAbsent {
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
      has.hashValue
    case let .failure(err):
      "\(err)".hashValue
    }
  }
}
