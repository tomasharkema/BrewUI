//
//  Version.swift
//
//
//  Created by Tomas Harkema on 13/10/2023.
//

import Foundation

public struct Version: Hashable {
  let version: SemanticVersion
  let isDependency: Bool
}

extension Version: Identifiable {
  public var id: Int {
    hashValue
  }
}

extension Version: CustomStringConvertible {
  public var description: String {
    if isDependency {
      return "DEP \(version)"
    } else {
      return "\(version)"
    }
  }
}

extension Version: Comparable {
  public static func < (lhs: Version, rhs: Version) -> Bool {
    return lhs.version < rhs.version
  }
}
