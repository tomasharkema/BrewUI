//
//  AllPackagesView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftData
import SwiftUI
import BrewCore

struct AllPackagesView: View {
    @Binding var selection: PackageIdentifier?
    @MainActor @Binding var searchTextOrNil: String?
    @ObservedObject var brewService = BrewService.shared

    @Query var all: [PackageCache]

    @ViewBuilder
    var list: some View {
        if let queryResult = brewService.queryResult {
            List(
                queryResult,
                selection: $selection
            ) { item in
                ItemView(info: item, showInstalled: true)
            }
        } else {
            List(
                all,
                selection: $selection
            ) { item in
                ItemView(info: item.result!, showInstalled: true)
            }
        }
    }

    var body: some View {
        list.task {
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
