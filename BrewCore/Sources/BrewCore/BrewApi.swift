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

    private nonisolated func request<ResultType: Codable>(
        url: URL,
        _: ResultType.Type
    ) async throws -> ResultType {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "no http response", code: 0)
        }

//        for (name, value) in httpResponse.allHeaderFields {
//            print("\(name) \(value)")
//        }

        guard (200 ..< 400).contains(httpResponse.statusCode) else {
            throw NSError(domain: "status code", code: httpResponse.statusCode)
        }

        #if DEBUG
            dispatchPrecondition(condition: .notOnQueue(.main))
        #endif

        let result = try decoder.decode(
            ResultType.self,
            from: data
        )

        return result
    }

    public nonisolated func formula() async throws -> [PartialCodable<InfoResult>] {
        try await request(
            url: URL(string: "https://formulae.brew.sh/api/formula.json")!,
            [PartialCodable<InfoResult>].self
        )
    }

    public nonisolated func cask() async throws -> [PartialCodable<InfoResult>] {
        try await request(
            url: URL(string: "https://formulae.brew.sh/api/cask.json")!,
            [PartialCodable<InfoResult>].self
        )
    }
}
