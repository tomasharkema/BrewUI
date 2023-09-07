//
//  main.swift
//
//
//  Created by Tomas Harkema on 02/09/2023.
//

import Foundation
import BrewCore
import BrewShared

@main
struct Main {
    static func main() async throws {
        let api = BrewApi()

        let f = try await api.formula()

        print(f)
    }
}

// @main
// struct Main {
//     static func main() async throws {
//         let api = BrewApi.shared
//         let tmp = URL.temporaryDirectory
//         print(tmp)
//         let cache = try await BrewCache(container: .brew(url: .brewStorage)) //, inMemoryStore: true)

//         async let formulaRequest = api.formula()
//         async let caskRequest = api.cask()

//         let formula = try await formulaRequest
// //        let cask = try await caskRequest

// //        print(formula)
// //        print(cask)

//         try await cache.sync(all: formula.compactMap { $0.value })
//     }
// }
