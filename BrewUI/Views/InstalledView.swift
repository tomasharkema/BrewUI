//
//  InstalledView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftData
import SwiftUI
import BrewCore

struct InstalledView: View {
    @Binding 
    var selection: PackageIdentifier?

    @Query
    var installed: [InstalledCache]

    init(selection: Binding<PackageIdentifier?>) {
        _selection = selection
        var fd = FetchDescriptor<InstalledCache>(sortBy: [SortDescriptor(\InstalledCache.package!.sortValue)])
        fd.fetchLimit = BrewCache.globalFetchLimit
        _installed = Query(fd)
    }

    var body: some View {
        List(installed, selection: $selection) { item in
            ItemView(package: .cached(item.package), showInstalled: false)
        }
        .tag(TabViewSelection.installed)
        .tabItem {
            Text("Installed Packages")
        }
    }
}
