//
//  URLSession+fetch.swift
//
//
//  Created by Tomas Harkema on 14/09/2023.
//

import Foundation

enum HttpError: Error {
  case noHttpResponse(URLResponse)
  case unexpectedHttpResponse(HTTPURLResponse, Int)
}

extension URLSession {
  nonisolated func request<ResultType: Codable>(
    request: URLRequest,
    _: ResultType.Type,
    decoder: JSONDecoder = .init()
  ) async throws -> ResultType {
    let (data, response) = try await data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw HttpError.noHttpResponse(response) // NSError(domain: "no http response", code: 0)
    }

    guard (200 ..< 400).contains(httpResponse.statusCode) else {
      throw HttpError.unexpectedHttpResponse(httpResponse, httpResponse.statusCode)
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
