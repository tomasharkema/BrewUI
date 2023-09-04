//
//  Main.swift
//
//
//  Created by Tomas Harkema on 02/09/2023.
//

import Foundation
import BrewCore
import SwiftData

@main
struct Main {
    static func main() async throws {
        let api = BrewApi.shared
        
        let cache = try await BrewCache(container: .brew(url: URL.temporaryDirectory.appending(component: "brewui.store")))

        async let formulaRequest = api.formula()
        async let caskRequest = api.cask()

        let formula = try await formulaRequest
        //        let cask = try await caskRequest

        //        print(formula)
        //        print(cask)

        try await cache.sync(all: formula.compactMap { $0.value })
    }
}
