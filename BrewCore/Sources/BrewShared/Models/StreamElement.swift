//
//  StreamElement.swift
//
//
//  Created by Tomas Harkema on 11/09/2023.
//

import Foundation

public struct StreamElement: Equatable, Codable {
    public let level: Level
    public let rawEntry: String

    public init(level: Level, rawEntry: String) {
        self.level = level
        self.rawEntry = rawEntry
    }

    static func err(_ error: String) -> StreamElement {
        StreamElement(level: .err, rawEntry: error)
    }

    static func out(_ out: String) -> StreamElement {
        StreamElement(level: .out, rawEntry: out)
    }

    public enum Level: Codable {
        case out
        case err
        case dev
    }
}

extension [StreamElement] {
    var outErr: any Sequence<String> {
        lazy.filter { $0.level == .out || $0.level == .err }
            .map(\.rawEntry)
    }

    var outErrString: String {
        outErr
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var out: any Sequence<String> {
        lazy.filter { $0.level == .out }.map(\.rawEntry)
    }

    var outString: String {
        out
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var err: any Sequence<String> {
        lazy.filter { $0.level == .err }.map(\.rawEntry)
    }

    static func err(_ error: String) -> [StreamElement] {
        [.err(error)]
    }

    static func out(_ out: String) -> [StreamElement] {
        [.out(out)]
    }
}
