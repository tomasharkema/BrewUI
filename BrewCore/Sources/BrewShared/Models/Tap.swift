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

    public init(
        name: String, user: String, repo: String, path: String,
        installed: Bool, official: Bool, remote: String, json: Data, calculatedHash: Int
    ) {
        self.name = name
        self.user = user
        self.repo = repo
        self.path = path
        self.installed = installed
        self.official = official
        self.remote = remote
        self.json = json
    }

    public init(info: TapInfo, encoder: JSONEncoder = .init()) throws {
        encoder.outputFormatting.insert(.sortedKeys)

        self.name = info.name
        self.user = info.user
        self.repo = info.repo
        self.path = info.path
        self.installed = info.installed
        self.official = info.official
        self.remote = info.remote
        self.json = try encoder.encode(info)
    }
}

extension Tap: Identifiable {
    public var id: String {
        return name
    }
}

extension Tap: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(json)
    }
}
