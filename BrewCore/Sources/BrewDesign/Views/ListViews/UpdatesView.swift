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
  private var updateService: BrewUpdateService

  @Binding
  private var selection: PackageIdentifier?

  @Query(
    FetchDescriptor<PackageCache>(
      predicate: #Predicate {
        $0.outdated && $0.hasInstalledVersion
      },
      sortBy: [SortDescriptor(\.identifier)]
    )
    .withFetchLimit(BrewCache.globalFetchLimit)
  )
  private var outdated: [PackageCache]

  @Query(
    FetchDescriptor<PackageCache>(
      predicate: #Predicate {
        $0.outdated && $0.hasInstalledAsDependencyVersion
      },
      sortBy: [SortDescriptor(\.identifier)]
    )
    .withFetchLimit(BrewCache.globalFetchLimit)
  )
  private var outdatedDeps: [PackageCache]

  public init(selection: Binding<PackageIdentifier?>) {
    _selection = selection
  }

  public var body: some View {
    List {
      Section("Outdated") {
        ForEach(outdated) { item in
          ItemView(package: .cached(item), showInstalled: false)
        }
      }
      Section("Outdated Dependencies") {
        ForEach(outdatedDeps) { item in
          ItemView(package: .cached(item), showInstalled: false)
        }
      }
    }
    .refreshable {
      await updateService.update()
    }
    .tabItem {
      Text("Updates (\(outdated.count))")
    }
  }
}
