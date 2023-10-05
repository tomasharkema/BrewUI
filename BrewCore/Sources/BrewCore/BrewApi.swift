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
import Inject

public final class BrewApi {
    private let session = URLSession(configuration: .default)
    private let decoder = JSONDecoder()

    public init() {}

    public nonisolated func formula() async throws -> [PartialCodable<InfoResultOnlyRemote>] {
        let request = URLRequest(
            url: URL(string: "https://formulae.brew.sh/api/formula.json")!,
            cachePolicy: .returnCacheDataElseLoad
        )
        return try await session.request(
            request: request,
            [PartialCodable<InfoResultOnlyRemote>].self,
            decoder: decoder
        )
    }

    public nonisolated func cask() async throws -> [PartialCodable<InfoResult>] {
        let request = URLRequest(
            url: URL(string: "https://formulae.brew.sh/api/cask.json")!,
            cachePolicy: .returnCacheDataElseLoad
        )
        return try await session.request(
            request: request,
            [PartialCodable<InfoResult>].self,
            decoder: decoder
        )
    }
}

extension InjectedValues {
    var brewApi: BrewApi {
        get { Self[BrewApiKey.self] }
        set { Self[BrewApiKey.self] = newValue }
    }
}

private struct BrewApiKey: InjectionKey {
    static var currentValue: BrewApi = BrewApi()
}
