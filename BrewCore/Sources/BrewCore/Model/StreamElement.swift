//
//  StreamElement.swift
//
//
//  Created by Tomas Harkema on 11/09/2023.
//

import Foundation

public struct StreamElement: Equatable {
    public let level: Level
    public let rawEntry: String
    public let attributedString: AttributedString

    init(level: Level, rawEntry: String) {
        self.level = level
        self.rawEntry = rawEntry

        switch level {
        case .dev:
            var attr = AttributedString(rawEntry)
            attr.foregroundColor = .blue
            attributedString = attr
        case .err:
            var attr = AttributedString(rawEntry)
            attr.foregroundColor = .red
            attributedString = attr
        case .out:
            let attr = AttributedString(rawEntry)
            attributedString = attr
        }
    }

    static func err(_ error: String) -> StreamElement {
        StreamElement(level: .err, rawEntry: error)
    }

    static func out(_ out: String) -> StreamElement {
        StreamElement(level: .out, rawEntry: out)
    }

    public enum Level {
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
