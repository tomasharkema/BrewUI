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
    @Binding var selection: PackageIdentifier?
    @Query
    var outdated: [OutdatedCache]

    init(selection: Binding<PackageIdentifier?>) {
        _selection = selection
        var fd = FetchDescriptor<OutdatedCache>(sortBy: [SortDescriptor(\OutdatedCache.package!.sortValue)])
        fd.fetchLimit = BrewCache.globalFetchLimit
        _outdated = Query(fd)
    }

    var body: some View {
        VStack {
            List(outdated, selection: $selection) { item in
                ItemView(package: .cached(item.package), showInstalled: false)
            }
//            if isLoading {
//                ProgressView().progressViewStyle(.circular)
//            }
        }
        .tag(TabViewSelection.updates)
        .tabItem {
            Text("Updates (\(outdated.count))")
        }
    }
}
