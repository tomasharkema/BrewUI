//
//  MainContainer.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import Foundation
import SwiftUI

struct MainContainer: View {
    @State
    private var dependencies: Dependencies?

    var body: some View {
        Group {
            if let dependencies {
                MainView()
                    .modelContainer(dependencies.modelContainer)
                    .environmentObject(dependencies.brewService)
                    .environmentObject(dependencies.search)
            } else {
                ProgressView().progressViewStyle(.circular)
            }
        }.task {
            if dependencies == nil {
                dependencies = await Dependencies.shared()
            }
        }
    }
}
