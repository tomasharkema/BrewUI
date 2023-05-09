//
//  InstalledView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftUI

struct InstalledView: View {
  @Binding var selection: InfoResult?

  @ObservedObject var brewService = BrewService.shared

  var body: some View {
    List(brewService.cacheInstalledSorted, id: \.self, selection: $selection) { item in
      ItemView(info: item, showInstalled: false)
    }
    .task {
      do {
        _ = try await BrewService.shared.listInstalledItems()
      } catch {
        print(error)
      }
    }
    .tag(TabViewSelection.installed)
    .tabItem {
      Text("Installed Packages")
    }
  }
}
