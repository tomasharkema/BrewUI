//
//  MainContainer.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import Foundation
import SwiftUI
import BrewDesign

struct MainContainer: View {
    @State
    private var dependencies: Dependencies?

    var body: some View {
        Group {
            if let dependencies {
                MainView()
                    .modelContainer(dependencies.modelContainer)
                    .environmentObject(dependencies.search)
                    .environmentObject(dependencies.brewService)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }.task {
            do {
                if dependencies == nil {
                    dependencies = try await Dependencies.shared()
                }
            } catch {
                print(error)
            }
        }
    }
}
