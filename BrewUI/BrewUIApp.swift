//
//  BrewUIApp.swift
//  BrewUI
//
//  Created by Tomas Harkema on 05/05/2023.
//

import SwiftData
import SwiftUI

@main
struct BrewUIApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(BrewService.shared.cache.modelContainer)
        }
    }
}
