//
//  AllPackagesView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftUI

struct AllPackagesView: View {
  @Binding var selection: PackageIdentifier?
  @MainActor @Binding var searchTextOrNil: String?
  @ObservedObject var brewService = BrewService.shared

  var body: some View {
    List(
      brewService.queryResult ?? brewService.cacheAllSorted, id: \.full_name,
      selection: $selection
    ) { item in
      ItemView(info: item, showInstalled: true)
    }
    .task {
      do {
        _ = try await BrewService.shared.update()
      } catch {
        print(error)
      }
    }
    .tag(TabViewSelection.all)
    .tabItem {
      Text("All Packages")
    }
  }
}
