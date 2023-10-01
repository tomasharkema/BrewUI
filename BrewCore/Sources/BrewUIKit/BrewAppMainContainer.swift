//
//  BrewAppMainContainer.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import BrewDesign
import Foundation
import SwiftUI

public struct BrewAppMainContainer: View {
    @State
    private var dependencies: Dependencies?

    public init() {}

    public var body: some View {
        Group {
            if let dependencies {
                MainView()
                    .modelContainer(dependencies.modelContainer)
                    .environmentObject(dependencies.search)
                    .environmentObject(dependencies.brewService)
                    .environmentObject(dependencies.update)
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
