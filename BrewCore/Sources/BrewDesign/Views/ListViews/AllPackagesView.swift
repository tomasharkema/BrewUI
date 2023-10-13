//
//  AllPackagesView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import BrewCore
import BrewShared
import SwiftData
import SwiftUI

public struct AllPackagesView: View {
  @EnvironmentObject
  private var updateService: BrewUpdateService

  @Binding
  private var selection: PackageIdentifier?

  @Query(
    FetchDescriptor<PackageCache>(
      sortBy: [SortDescriptor(\.sortValue)]
    ).withFetchLimit(BrewCache.globalFetchLimit)
  )
  private var all: [PackageCache]

  public init(selection: Binding<PackageIdentifier?>) {
    _selection = selection
  }

  public var body: some View {
    List(
      all,
      selection: $selection
    ) { item in
      ItemView(package: .cached(item), showInstalled: true)
    }
    .refreshable {
      await updateService.update()
    }
  }
}
