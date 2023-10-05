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
        self.calculatedHash = json.sha256Hash()
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

        let json = try encoder.encode(info)
        self.json = json
        self.calculatedHash = json.sha256Hash()
    }

    public func update(tapInfo: TapInfo, encoder: JSONEncoder = .init()) throws {
        encoder.outputFormatting.insert(.sortedKeys)

        self.name = tapInfo.name
        self.user = tapInfo.user
        self.repo = tapInfo.repo
        self.path = tapInfo.path
        self.installed = tapInfo.installed
        self.official = tapInfo.official
        self.remote = tapInfo.remote

        let json = try encoder.encode(tapInfo)
        self.json = json
        self.calculatedHash = json.sha256Hash()
    }
}

extension Tap: Identifiable {
    public var id: String {
        return name
    }
}

extension Tap: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(calculatedHash)
    }
}
