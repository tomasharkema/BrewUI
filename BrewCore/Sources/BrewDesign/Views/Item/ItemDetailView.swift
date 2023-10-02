//
//  ItemDetailView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import BrewCore
import BrewShared
import SwiftData
import SwiftUI

public struct ItemDetailView: View {
    //  @Namespace var bottomID
    //  @Environment(\.dismiss) var dismiss
    private let package: PackageIdentifier

    private let service: BrewService

    @EnvironmentObject
    var processService: BrewProcessService

    @Query
    private var items: [PackageCache]

    @StateObject
    private var updateService: BrewUpdateService

    public init(
        package: PackageIdentifier,
        service: BrewService,
        processService: BrewProcessService
    ) {
        let pred = #Predicate<PackageCache> {
            $0.identifier == package.description
        }
        var fetcher = FetchDescriptor<PackageCache>(predicate: pred)
        fetcher.fetchLimit = 1
        _items = Query(fetcher)
        self.package = package

        self.service = service
        _updateService = .init(
            wrappedValue: BrewUpdateService(service: service, processService: processService)
        )
    }

    public var body: some View {
        if let item = items.first {
            ItemDetailItemView(
                package: .cached(item)
            ).environmentObject(updateService)
        } else {
            Text("Package not found...")
        }
    }
}
