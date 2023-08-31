//
//  InstalledView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftUI

struct InstalledView: View {
  @Binding var selection: PackageIdentifier?

  @ObservedObject var brewService = BrewService.shared

  var body: some View {
    List(brewService.cacheInstalledSorted, id: \.full_name, selection: $selection) { item in
      ItemView(info: item, showInstalled: false)
    }
    .task {
      do {
        _ = try await BrewService.shared.update()
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
