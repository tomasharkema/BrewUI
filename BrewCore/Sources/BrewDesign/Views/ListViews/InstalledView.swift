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
  private var updateService: BrewUpdateService

  @Binding
  var selection: PackageIdentifier?

  @Query(
    FetchDescriptor<PackageCache>(
      predicate: #Predicate {
        $0.hasInstalledVersion
      },
      sortBy: [SortDescriptor(\.identifier)]
    )
//            .withFetchLimit(BrewCache.globalFetchLimit)
  )
  private var installed: [PackageCache]

  public init(selection: Binding<PackageIdentifier?>) {
    _selection = selection
  }

  public var body: some View {
    List(installed, selection: $selection) { item in
      ItemView(package: .cached(item), showInstalled: false)
    }
    .refreshable {
      await updateService.update()
    }
    .tabItem {
      Text("Installed Packages (\(installed.count))")
    }
  }
}
