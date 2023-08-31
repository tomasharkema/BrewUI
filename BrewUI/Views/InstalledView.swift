//
//  InstalledView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftData
import SwiftUI

struct InstalledView: View {
    @Binding var selection: PackageIdentifier?

    @Query var installed: [InstalledCache]

    var body: some View {
        List(installed, selection: $selection) { item in
            ItemView(info: item.result!, showInstalled: false)
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
