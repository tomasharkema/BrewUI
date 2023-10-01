//
//  BrewApi.swift
//
//
//  Created by Tomas Harkema on 01/09/2023.
//

import BrewShared
import Foundation
import RawJson
import SwiftData
import SwiftUI

public final class BrewApi {
    private let session = URLSession(configuration: .default)
    private let decoder = JSONDecoder()

    public init() {}

    public nonisolated func formula() async throws -> [PartialCodable<InfoResult>] {
        let request = URLRequest(url: URL(string: "https://formulae.brew.sh/api/formula.json")!, cachePolicy: .returnCacheDataElseLoad)
        return try await session.request(
            request: request,
            [PartialCodable<InfoResult>].self,
            decoder: decoder
        )
    }

    public nonisolated func cask() async throws -> [PartialCodable<InfoResult>] {
        let request = URLRequest(url: URL(string: "https://formulae.brew.sh/api/cask.json")!, cachePolicy: .returnCacheDataElseLoad)
        return try await session.request(
            request: request,
            [PartialCodable<InfoResult>].self,
            decoder: decoder
        )
    }
}
