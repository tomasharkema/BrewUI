//
//  ModelHasher.swift
//
//
//  Created by Tomas Harkema on 13/10/2023.
//

import Foundation
import CryptoKit

public protocol StableHashable { }

public extension StableHashable where Self: Encodable {
  func stableHash() throws -> (json: Data, hash: String) {
    let encoder = JSONEncoder()
    encoder.outputFormatting.insert(.sortedKeys)
    let json = try encoder.encode(self)
    return (json, json.sha256Hash())
  }
}

public protocol StableHashDataProviding {
  var stableHashData: Data { get }
}

public extension StableHashDataProviding {
  func stableHash() -> String {
    return stableHashData.sha256Hash()
  }
}

extension Data {
  public func stableHash() -> String {
    self.sha256Hash()
  }

  fileprivate func sha256Hash() -> String {
    SHA256.hash(data: self).compactMap { String(format: "%02x", $0) }.joined()
  }
}
