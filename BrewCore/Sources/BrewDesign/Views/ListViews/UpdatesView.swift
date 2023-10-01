//
//  UpdatesView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import BrewCore
import BrewShared
import SwiftData
import SwiftUI

public struct UpdatesView: View {
    @EnvironmentObject
    var update: BrewUpdateService

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
        .refreshable {
            do {
                try await update.update()
            } catch {
                print(error)
            }
        }
        .tabItem {
            Text("Updates (\(outdated.count))")
        }
    }
}
