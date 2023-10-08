//
//  BrewAppMainContainer.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import BrewCore
import BrewDesign
import Foundation
import SwiftUI
import Inject

public struct BrewAppMainContainer: View {
    @State
    private var dependencies: Dependencies?

    public init() {}

    public var body: some View {
        Group {
            if let dependencies {
                MainTabView()
                    .modelContainer(dependencies.modelContainer)
                    .environmentObject(dependencies.updateService)
//                    .environmentObject(dependencies.search)
//                    .environmentObject(dependencies.brewService)
//                    .environmentObject(dependencies.processService)
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
