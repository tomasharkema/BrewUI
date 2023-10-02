//
//  TapsView.swift
//
//
//  Created by Tomas Harkema on 02/10/2023.
//

import SwiftUI
import SwiftData
import BrewShared
import BrewCore

public struct TapsView: View {

    @Query(
        FetchDescriptor<Tap>(sortBy: [SortDescriptor(\.name)])
    )
    private var taps: [Tap]

    public init() {}

    public var body: some View {
        List(taps) { tap in
            Text(tap.name).font(.body.monospaced())
        }
    }
}