//
//  MainView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import BrewCore
import BrewDesign
import BrewShared
import SwiftUI
import Processed

struct MainView: View {
    @State
    private var searchText = ""

    @AppStorage("tabviewSelection")
    private var tabviewSelection = TabViewSelection.installed

    @State
    private var selection: PackageIdentifier?

    @EnvironmentObject
    var service: BrewService

    @EnvironmentObject
    var searchService: BrewSearchService

    @EnvironmentObject
    var updateService: BrewUpdateService

    var body: some View {
        TabView(selection: $tabviewSelection) {
            InstalledView(selection: $selection)
                .tag(TabViewSelection.installed)
                .tabItem {
                    Text("Installed Packages")
                }

            UpdatesView(selection: $selection)
                .tag(TabViewSelection.updates)
                .tabItem {
                    Text("Updates")
                }

            AllPackagesView(selection: $selection)
                .tag(TabViewSelection.all)
                .tabItem {
                    Text("All Packages")
                }

            SearchResultView(selection: $selection)
                .tag(TabViewSelection.searchResult)
                .tabItem {
                    Text("Search")
                }
        }
        .sheet(item: $selection, onDismiss: {
            selection = nil
        }) { item in
            ItemDetailView(package: item).padding()
        }
        .task {
            await updateService.update()
        }
        .errorAlert(state: updateService.updating)
        .task(id: searchText) {
            await searchService.search(query: searchText)
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { old, new in
            guard old != new else { return }
            if new.count >= 3 {
                if tabviewSelection != .searchResult {
                    tabviewSelection = .searchResult
                }
            }
        }
        .padding()
        .background(PublicColor.backgroundTint)
        .scrollContentBackground(.hidden)
        .navigationTitle("🍺 BrewUI")
        .sheet(item: .constant(updateService.stream)) {
            StreamingView(stream: $0) {
                fatalError("DONE!")
//                stream = nil
            }
        }
        .toolbar {
            ToolbarItemGroup {
                PackageButton(type: .upgradeAll)

                PackageButton(type: .updateAll)
            }
        }
    }
}
