//
//  BrewShippedFile.swift
//
//
//  Created by Tomas Harkema on 14/10/2023.
//

import Foundation
import RawJson
import BrewShared
import Inject
import Gzip

public final class BrewShippedFile {
  private let decoder: JSONDecoder

  public init(decoder: JSONDecoder = .init()) {
    self.decoder = decoder
  }

  private nonisolated func localFile<ResultType: Decodable>(name: String) async throws -> ResultType {
    do {
      guard let fileUrl = Bundle.module.url(forResource: name, withExtension: "json.gz") else {
        throw NSError(domain: "file not found \(name)", code: 0)
      }

      let data = try Data(contentsOf: fileUrl)
      let decompressedData = try data.gunzipped()
      return try decoder.decode(ResultType.self, from: decompressedData)
    } catch {
      print(error)
      throw error
    }
  }

  private nonisolated func localFileUpdated(name: String) async throws -> LocalFileLastUpdated {
    do {
      guard let fileUrl = Bundle.module.url(forResource: "\(name).update", withExtension: "log") else {
        throw NSError(domain: "file not found \(name)", code: 0)
      }

      let data = try Data(contentsOf: fileUrl)
      let string = String(data: data, encoding: .utf8)
      let regex = /(?<date>[0-9]*);(?<hash>\S*)/

      guard let match = string?.firstMatch(of: regex) else {
        throw NSError(domain: "no match \(name)", code: 0)
      }

      guard let dateInt = Double(String(match.output.date)) else {
        throw NSError(domain: "no date \(name)", code: 0)
      }

      let date = Date(timeIntervalSince1970: dateInt)

      return LocalFileLastUpdated(updatedDate: date, updatedHashValue: String(match.output.hash))

    } catch {
      print(error)
      throw error
    }
  }

  nonisolated func localFormulaUpdate() async throws -> LocalFileLastUpdated {
    return try await localFileUpdated(name: "formula")
  }

  public nonisolated func localFormula() async throws -> [PartialCodable<InfoResultOnlyRemote>] {
    return try await localFile(name: "formula")
  }
}

extension InjectedValues {
  var brewShippedFileKey: BrewShippedFile {
    get { Self[BrewShippedFileKey.self] }
    set { Self[BrewShippedFileKey.self] = newValue }
  }
}

private struct BrewShippedFileKey: InjectionKey {
  static var currentValue: BrewShippedFile = .init()
}
