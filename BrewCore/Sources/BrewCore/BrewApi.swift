//
//  BrewApi.swift
//
//
//  Created by Tomas Harkema on 01/09/2023.
//

import Foundation
import SwiftData
import SwiftUI
import RawJson

public final class BrewApi {

    public static let shared = BrewApi()

    private let session: URLSession
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config)
    }

    private func request<ResultType: Codable>(url: URL, _ resultType: ResultType.Type) async throws -> ResultType {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "no http response", code: 0)
        }

        for (name, value) in httpResponse.allHeaderFields {
            print("\(name) \(value)")
        }

        guard (200..<400).contains(httpResponse.statusCode) else {
            throw NSError(domain: "status code", code: httpResponse.statusCode)
        }

        dispatchPrecondition(condition: .notOnQueue(.main))
        let result = try decoder.decode(
            ResultType.self,
            from: data
        )
        
        return result
    }

    public func formula() async throws -> [PartialCodable<InfoResult>] {
        let result = try await request(url: URL(string: "https://formulae.brew.sh/api/formula.json")!, [PartialCodable<InfoResult>].self)
        return result
    }

    public func cask() async throws -> [PartialCodable<InfoResult>] {
        let result = try await request(url: URL(string: "https://formulae.brew.sh/api/cask.json")!, [PartialCodable<InfoResult>].self)
        return result
    }
}
