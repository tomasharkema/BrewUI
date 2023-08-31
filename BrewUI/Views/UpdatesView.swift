//
//  UpdatesView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftData
import SwiftUI

struct UpdatesView: View {
    @MainActor @State var updates = [InfoResult]()
    @Binding var selection: PackageIdentifier?
    @State var isLoading = false
    //  @ObservedObject var brewService = BrewService.shared

    @Query var outdated: [OutdatedCache]

    var body: some View {
        Group {
            if isLoading {
                ProgressView().progressViewStyle(.circular)
            } else {
                List(outdated, selection: $selection) { item in
                    ItemView(info: item.result!, showInstalled: false)
                }
            }
        }
        .task {
            do {
                isLoading = true
                defer {
                    isLoading = false
                }
                try await BrewService.shared.update()
            } catch {
                print(error)
            }
        }
        .tag(TabViewSelection.updates)
        .tabItem {
            Text("Updates")
        }
    }
}
