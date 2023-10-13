//
//  TapItemView.swift
//
//
//  Created by Tomas Harkema on 02/10/2023.
//

import BrewShared
import SwiftData
import SwiftUI

struct TapItemView: View {
  private let tap: Tap

  @Query
  private var packages: [PackageCache]

  init(tap: Tap) {
    self.tap = tap

    let name = tap.name
    var descriptor = FetchDescriptor<PackageCache>()
    descriptor.predicate = #Predicate {
      $0.tap == name
    }
    _packages = Query(descriptor)
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(tap.name)
        .foregroundColor(Color(.foregroundTint))
      Text("packages: \(packages.count)")
    }.font(.body.monospaced())
  }
}
