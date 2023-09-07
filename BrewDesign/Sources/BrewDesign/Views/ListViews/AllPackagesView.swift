//
//  AllPackagesView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftData
import SwiftUI
import BrewCore
import BrewShared

public struct AllPackagesView: View {
    @Binding
    private var selection: PackageIdentifier?

    @Query(
        FetchDescriptor<PackageCache>(sortBy: [SortDescriptor(\.sortValue)])
            .withFetchLimit(BrewCache.globalFetchLimit)
    )
    private var all: [PackageCache]

    public init(selection: Binding<PackageIdentifier?>) {
        self._selection = selection
    }

    public var body: some View {
        List(
            all,
            selection: $selection
        ) { item in
            ItemView(package: .cached(item), showInstalled: true)
        }
    }
}
