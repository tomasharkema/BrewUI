//
//  Tap.swift
//
//
//  Created by Tomas Harkema on 02/10/2023.
//

import Foundation
import SwiftData

@Model
public final class Tap {
  @Attribute(.unique)
  public var name: String

  public var user: String
  public var repo: String
  public var path: String
  public var installed: Bool
  public var official: Bool
  public var remote: String

  public var json: Data
  public var calculatedHash: String

  public init(
    name: String, user: String, repo: String, path: String,
    installed: Bool, official: Bool, remote: String, json: Data
  ) {
    self.name = name
    self.user = user
    self.repo = repo
    self.path = path
    self.installed = installed
    self.official = official
    self.remote = remote
    self.json = json

    calculatedHash = json.stableHash()
  }

  public init(info: TapInfo) throws {
    name = info.name
    user = info.user
    repo = info.repo
    path = info.path
    installed = info.installed
    official = info.official
    remote = info.remote

    let (json, hash) = try info.stableHash()
    self.json = json
    calculatedHash = hash
  }

  public func update(tapInfo: TapInfo) throws {
    name = tapInfo.name
    user = tapInfo.user
    repo = tapInfo.repo
    path = tapInfo.path
    installed = tapInfo.installed
    official = tapInfo.official
    remote = tapInfo.remote

    let (json, hash) = try tapInfo.stableHash()
    self.json = json
    calculatedHash = hash
  }
}

//extension Tap: StableHashable {
//  public var stableHashData: Data {
//    json
//  }
//}

extension Tap: Identifiable {
  public var id: String {
    name
  }
}

extension Tap: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(calculatedHash)
  }
}
