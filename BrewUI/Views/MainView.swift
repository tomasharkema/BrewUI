//
//  MainView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftUI
import BrewCore

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
    var searchText = ""

    @AppStorage("tabviewSelection") 
    var tabviewSelection = TabViewSelection.installed

    @State 
    var selectionInstalled = Set<InfoResult>()
    @State 
    var selection: PackageIdentifier?

    @State 
    var presentedError: Error?
    @State 
    var errorIsPresented = false

    var body: some View {
        TabView(selection: $tabviewSelection) {
            InstalledView(selection: $selection)

            UpdatesView(selection: $selection)

            AllPackagesView(selection: $selection)
            #if DEBUG
            PackageTable()
            #endif

//            PackageNewDesign(selection: $selection)

            SearchResult(selection: $selection)
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
                errorIsPresented = true
            }
        }
        .alert(Text("Error"), isPresented: $errorIsPresented) {
            if let presentedError = self.presentedError {
                Text("Error: \(String(describing: presentedError))")
                Button("OK", role: .cancel) { }
            }
        }
        .task(id: searchText) {
            do {
                try await Dependencies.shared().search.search(query: searchText)
            } catch {
                if error is CancellationError {
                    return
                }
                print("search error \(error)")
                presentedError = error
                errorIsPresented = true
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
        .background(Color(.background))
        .scrollContentBackground(.hidden)
        .navigationTitle("🍺 BrewUI")
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
