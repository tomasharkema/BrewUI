//
//  URLSession+fetch.swift
//
//
//  Created by Tomas Harkema on 14/09/2023.
//

import Foundation

extension URLSession {
    nonisolated func request<ResultType: Codable>(
        request: URLRequest,
        _: ResultType.Type,
        decoder: JSONDecoder = .init()
    ) async throws -> ResultType {
        let (data, response) = try await data(for: request)

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
}
