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

struct InfoResult: Codable, Hashable {
    let name: String
    let full_name: PackageIdentifier
    let tap: String
    let desc: String?
    let license: String?
    let homepage: String
    let installed: [InstalledVersion]
    let versions: Versions

    let pinned: Bool
    let outdated: Bool
    let deprecated: Bool
    let deprecation_date: String?
    let deprecation_reason: String?
    let disabled: Bool
    let disable_date: String?
    let disable_reason: String?
    //  let service: String?
}

struct InstalledVersion: Codable, Hashable {
    let version: String
    let installed_as_dependency: Bool
}

struct Versions: Codable, Hashable {
    let stable: String?
    let head: String?
}

struct PackageIdentifier: RawRepresentable, Hashable, Transferable {
    let rawValue: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .packageIdentifierType)
    }
}

extension UTType {
    static let packageIdentifierType = UTType(exportedAs: "io.harkema.packageIdentifierType")
}

extension PackageIdentifier: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension PackageIdentifier: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }
}

extension PackageIdentifier: Identifiable {
    var id: Int {
        hashValue
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

typealias InfoResultSort = [InfoResult]

extension InfoResultSort: RawRepresentable {
    public init?(rawValue: String) {
        do {
            let res = try JSONDecoder().decode(
                [InfoResult].self,
                from: rawValue.data(using: .utf8)!
            )
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
