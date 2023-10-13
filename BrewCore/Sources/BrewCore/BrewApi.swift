//
//  BrewApi.swift
//
//
//  Created by Tomas Harkema on 01/09/2023.
//

import BrewShared
import Foundation
import Inject
import RawJson

public final class BrewApi {
  private let session: URLSession
  private let decoder: JSONDecoder

  private let endpoint = URL(string: "https://formulae.brew.sh/api/")!

  public init(session: URLSession = URLSession.shared, decoder: JSONDecoder = .init()) {
    self.session = session
    self.decoder = decoder
  }

  public nonisolated func formula() async throws -> [PartialCodable<InfoResultOnlyRemote>] {
    let request = URLRequest(
      url: endpoint.appending(path: "formula.json"),
      cachePolicy: .returnCacheDataElseLoad
    )
    return try await session.request(
      request: request,
      [PartialCodable<InfoResultOnlyRemote>].self,
      decoder: decoder
    )
  }

  public nonisolated func cask() async throws -> [PartialCodable<InfoResponse>] {
    let request = URLRequest(
      url: endpoint.appending(path: "cask.json"),
      cachePolicy: .returnCacheDataElseLoad
    )
    return try await session.request(
      request: request,
      [PartialCodable<InfoResponse>].self,
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
  static var currentValue: BrewApi = .init()
}
