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
    @Query//(sort: \PackageCache.sortValue)
    var all: [PackageCache]

    init(selection: Binding<PackageIdentifier?>) {
        _selection = selection
        var fd = FetchDescriptor<PackageCache>(sortBy: [SortDescriptor(\.sortValue)])
        fd.fetchLimit = BrewCache.globalFetchLimit
        _all = Query(fd)
    }


    var body: some View {
        List(
            all,
            selection: $selection
        ) { item in
            ItemView(package: .cached(item), showInstalled: true)
        }
        .tag(TabViewSelection.all)
        .tabItem {
            Text("All Packages")
        }
    }
}
