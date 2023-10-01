//
//  StdErr.swift
//
//
//  Created by Tomas Harkema on 10/09/2023.
//

import BrewShared
import Foundation

public struct StdErr: Error {
    public let out: CommandOutput
    public let command: String

    init(out: CommandOutput, command: String) {
        self.out = out
        self.command = command
    }

    init(stream: [StreamElement], command: String) {
//        let stdout = stream.lazy.filter {
//            $0.level == .out
//        }
//        .map(\.rawEntry)
//        .joined(separator: "\n")
//
//        let stderr = stream.lazy.filter {
//            $0.level == .err
//        }
//        .map(\.rawEntry)
//        .joined(separator: "\n")

        out = .init(stream: stream)
        self.command = command
    }
}
