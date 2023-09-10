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

    @Query
    private var items: [PackageCache]

    public init(package: PackageIdentifier) {
        let pred = #Predicate<PackageCache> {
            $0.identifier == package.description
        }
        var fetcher = FetchDescriptor<PackageCache>(predicate: pred)
        fetcher.fetchLimit = 1
        _items = Query(fetcher)
        self.package = package
    }

    public var body: some View {
        if let item = items.first {
            ItemDetailItemView(package: .cached(item))
        } else {
            Text("Package not found...")
        }
    }
}
