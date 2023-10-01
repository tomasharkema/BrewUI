//
//  InstalledView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import BrewCore
import BrewShared
import SwiftData
import SwiftUI

public struct InstalledView: View {
    @EnvironmentObject
    var service: BrewUpdateService

    @Binding
    var selection: PackageIdentifier?

    @Query(
        FetchDescriptor<InstalledCache>(sortBy: [SortDescriptor(\.identifier)])
            .withFetchLimit(BrewCache.globalFetchLimit)
    )
    private var installed: [InstalledCache]

    public init(selection: Binding<PackageIdentifier?>) {
        _selection = selection
    }

    public var body: some View {
        List(installed, selection: $selection) { item in
            ItemView(package: .cached(item.package), showInstalled: false)
        }
        .refreshable {
            await service.update()
        }
    }
}
