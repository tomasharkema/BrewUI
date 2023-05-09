//
//  MainView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftUI

enum TabViewSelection: String, Hashable {
  case installed
  case updates
  case all
}

struct MainView: View {
  @MainActor @State var searchText = ""
  @MainActor @State var searchTextOrNil: String?

  @MainActor @AppStorage("tabviewSelection") var tabviewSelection = TabViewSelection.installed

  @MainActor @State var selectionInstalled = Set<InfoResult>()
  @MainActor @State var selection: InfoResult?

  @ObservedObject var brewService: BrewService = .shared

  @MainActor @State var stream: StreamOutput?

  var body: some View {
    TabView(selection: $tabviewSelection) {

      InstalledView(selection: $selection)

      UpdatesView(selection: $selection)

      AllPackagesView(selection: $selection, searchTextOrNil: $searchTextOrNil)

    }
    .sheet(item: $selection, onDismiss: {
      selection = nil
    }) { item in
      ItemDetailView(item: item).padding()
    }
    .task(id: searchTextOrNil) {
      do {
        try await BrewService.shared.search(query: searchTextOrNil)
      } catch {
        print(error)
      }
    }
    .searchable(text: $searchText)
    .onChange(of: searchText) {
      if searchText == "" {
        searchTextOrNil = nil
      } else {
        searchTextOrNil = $0
        if tabviewSelection != .all {
          tabviewSelection = .all
        }
      }
    }
//    .padding()
    .background(Color("background"))
    .scrollContentBackground(.hidden)
    .navigationTitle("🍺 BrewUI")
  }
}

struct MainView_Previews: PreviewProvider {
  static var previews: some View {
    MainView()
  }
}
