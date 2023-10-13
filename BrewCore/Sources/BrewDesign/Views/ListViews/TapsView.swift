//
//  TapsView.swift
//
//
//  Created by Tomas Harkema on 02/10/2023.
//

import BrewShared
import SwiftData
import SwiftUI

public struct TapsView: View {
  @Query(
    FetchDescriptor<Tap>(sortBy: [SortDescriptor(\.name)])
  )
  private var taps: [Tap]

  public init() {}

  public var body: some View {
    if !taps.isEmpty {
      List(taps) { tap in
        TapItemView(tap: tap)
      }
    }
  }
}
