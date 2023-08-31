//
//  UpdatesView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftData
import SwiftUI
import BrewCore

struct UpdatesView: View {
    @MainActor @State var updates = [InfoResult]()
    @Binding var selection: PackageIdentifier?
    @State var isLoading = false
    //  @ObservedObject var brewService = BrewService.shared

    @Query(sort: \OutdatedCache.name) var outdated: [OutdatedCache]

    var body: some View {
        VStack {
            List(outdated, selection: $selection) { item in
                ItemView(info: item.result!, showInstalled: false)
            }
            if isLoading {
                ProgressView().progressViewStyle(.circular)
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
            Text("Updates (\(outdated.count))")
        }
    }
}
