//
//  MainView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftUI
import BrewCore
import BrewDesign
import BrewShared

enum TabViewSelection: String, Hashable {
    case installed
    case updates
    case all
    case table
//    case newDesign
    case searchResult
}

struct MainView: View {
    @State
    private var searchText = ""

    @AppStorage("tabviewSelection") 
    private var tabviewSelection = TabViewSelection.installed

    @State 
    private var selectionInstalled = Set<InfoResult>()
    @State
    private var selection: PackageIdentifier?

    @State 
    private var presentedError: Error?

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

            #if DEBUG
            _PackageTable()
                .tag(TabViewSelection.table)
                .tabItem {
                    Text("Table")
                }
            #endif
            
//            if false {
//                PackageNewDesign(selection: $selection)
//            }

            SearchResult(selection: $selection)
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
            do {
                try await Dependencies.shared().brewService.update()
            } catch {
                if error is CancellationError {
                    return
                }
                
                print("update error \(error)")

                presentedError = error
            }
        }
        .alert(error: $presentedError)
        .task(id: searchText) {
            do {
                try await Dependencies.shared().search.search(query: searchText)
            } catch {
                if error is CancellationError {
                    return
                }
                print("search error \(error)")
                presentedError = error
            }
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
        .background(PublicColor.background)
        .scrollContentBackground(.hidden)
        .navigationTitle("🍺 BrewUI")
    }
}

//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView()
//    }
//}

extension Binding {
    func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Binding<NewValue> {
        Binding<NewValue>(get: { transform(wrappedValue) }, set: { _ in })
    }
}
