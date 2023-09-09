//
//  UpdatesView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftData
import SwiftUI
import BrewCore
import BrewShared

public struct UpdatesView: View {
    @Binding 
    private var selection: PackageIdentifier?

    @Query(
        FetchDescriptor<OutdatedCache>(sortBy: [SortDescriptor(\.identifier)])
//            .withFetchLimit(BrewCache.globalFetchLimit)
    )
    private var outdated: [OutdatedCache]

    public init(selection: Binding<PackageIdentifier?>) {
        _selection = selection
    }

    public var body: some View {
        List(outdated, selection: $selection) { item in
            ItemView(package: .cached(item.package), showInstalled: false)
        }
        .tabItem {
            Text("Updates (\(outdated.count))")
        }
    }
}
