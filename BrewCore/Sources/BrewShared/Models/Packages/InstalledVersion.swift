//
//  InstalledVersion.swift
//  BrewUI
//
//  Created by Tomas Harkema on 31/08/2023.
//

import MetaCodable

@Codable
public struct InstalledVersion: Hashable, Sendable {
  public let version: String

  @CodedAt("installed_as_dependency")
  public let installedAsDependency: Bool
}
