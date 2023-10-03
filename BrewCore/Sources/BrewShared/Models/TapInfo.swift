//
//  TapInfo.swift
//
//
//  Created by Tomas Harkema on 02/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct TapInfo {
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

extension TapInfo: Hashable {
    public func hash(into hasher: inout Hasher) {
        let encoder = JSONEncoder()
        encoder.outputFormatting.insert(.sortedKeys)
        if let json = try? encoder.encode(self) {
            hasher.combine(json)
        }
    }
}

extension TapInfo: Identifiable {
    public var id: String {
        name
    }
}
