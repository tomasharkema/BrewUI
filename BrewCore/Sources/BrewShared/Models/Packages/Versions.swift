//
//  Versions.swift
//
//
//  Created by Tomas Harkema on 12/10/2023.
//

public struct Versions: Codable, Hashable, Sendable {
  public let stable: String?
  public let head: String?
}
