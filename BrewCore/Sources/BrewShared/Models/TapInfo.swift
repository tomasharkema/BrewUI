//
//  TapInfo.swift
//
//
//  Created by Tomas Harkema on 02/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct TapInfo: Sendable {
  public let name: String
  public let user: String
  public let repo: String
  public let path: String
  public let installed: Bool
  public let official: Bool
  @CodedAt("formula_names")
  public let formulaNames: [String]
  public let remote: String
}

extension TapInfo: StableHashable { }

extension TapInfo: Hashable {
  public func hash(into hasher: inout Hasher) {
    if let hash = try? self.stableHash() {
      hasher.combine(hash.1)
    }
  }
}

extension TapInfo: Identifiable {
  public var id: String {
    name
  }
}
