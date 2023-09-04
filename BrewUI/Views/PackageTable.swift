//
//  PackageTable.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import SwiftUI
import BrewCore
import SwiftData

#if DEBUG
struct PackageTable: View {

    @Query //(sort: \PackageCache.sortValue)
    var all: [PackageCache]

    init() {
        var fd = FetchDescriptor<PackageCache>(sortBy: [SortDescriptor(\.sortValue)])
        fd.fetchLimit = BrewCache.globalFetchLimit
        _all = Query(fd)
    }

    var body: some View {
        Table(all) {
            TableColumn("Package", value: \.baseName)
            TableColumn("Tap", value: \.tap)
            TableColumn("Installed Version") { package in
                Text(package.installedVersion ?? "")
            }
            TableColumn("Latest Version", value: \.versionsStable)
//            TableColumn("Description", value: \.desc)
        }
        .font(.body.monospaced())
        .tag(TabViewSelection.table)
        .tabItem {
            Text("Table")
        }
    }
}
#endif
