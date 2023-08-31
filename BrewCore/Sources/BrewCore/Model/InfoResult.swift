//
//  InfoResult.swift
//  BrewUI
//
//  Created by Tomas Harkema on 31/08/2023.
//

import CoreTransferable
import Foundation
import SwiftData
import UniformTypeIdentifiers

struct ListResult: Hashable {
    let name: String
    let version: String
    //  let cask: Bool
}

public struct InfoResult: Codable, Hashable {
    public let name: String
    public let full_name: PackageIdentifier
    public let tap: String
    public let desc: String?
    public let license: String?
    public let homepage: String
    public let installed: [InstalledVersion]
    public let versions: Versions

    public let pinned: Bool
    public let outdated: Bool
    public let deprecated: Bool
    public let deprecation_date: String?
    public let deprecation_reason: String?
    public let disabled: Bool
    public let disable_date: String?
    public let disable_reason: String?
    //  let service: String?
}

public struct InstalledVersion: Codable, Hashable {
    public let version: String
    public let installed_as_dependency: Bool
}

public struct Versions: Codable, Hashable {
    public let stable: String?
    public let head: String?
}

public struct PackageIdentifier: RawRepresentable, Hashable, Transferable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .packageIdentifierType)
    }
}

extension UTType {
    static let packageIdentifierType = UTType(exportedAs: "io.harkema.packageIdentifierType")
}

extension PackageIdentifier: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension PackageIdentifier: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }
}

extension PackageIdentifier: Identifiable {
    public var id: String {
        rawValue
    }
}

typealias InfoResultDict = [PackageIdentifier: InfoResult]

extension InfoResultDict: RawRepresentable {
    public init?(rawValue: String) {
        do {
            let res = try JSONDecoder()
                .decode([PackageIdentifier: InfoResult].self, from: rawValue.data(using: .utf8)!)
            self = res
        } catch {
            print(error)
            return nil
        }
    }

    public var rawValue: String {
        String(data: (try? JSONEncoder().encode(self))!, encoding: .utf8) ?? ""
    }
}

public typealias InfoResultSort = [InfoResult]
//
//extension InfoResultSort: RawRepresentable {
//    public init?(rawValue: String) {
//        do {
//            let res = try JSONDecoder().decode(
//                [InfoResult].self,
//                from: rawValue.data(using: .utf8)!
//            )
//            self = res
//        } catch {
//            print(error)
//            return nil
//        }
//    }
//
//    public var rawValue: String {
//        String(data: (try? JSONEncoder().encode(self))!, encoding: .utf8) ?? ""
//    }
//}

extension ListResult: Identifiable {
    public var id: Int {
        hashValue
    }
}

extension InfoResult: Identifiable {
    public var id: String {
        full_name.id
    }
}
