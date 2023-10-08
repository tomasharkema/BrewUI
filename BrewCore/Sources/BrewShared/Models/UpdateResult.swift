//
//  UpdateResult.swift
//
//
//  Created by Tomas Harkema on 11/09/2023.
//

import Foundation

public enum UpdateResult: Equatable {
    case alreadyUpToDate
    case updated(
        updatedTaps: Substring,
        updatedCasks: [Substring],
        newFormulae: [Substring],
        newCasks: [Substring],
        outdatedFormulae: [Substring],
        outdatedCasks: [Substring]
    )

    public init(_ command: CommandOutput) throws {
        if command.outErrString.contains("Already up-to-date") {
            self = .alreadyUpToDate
            return
        }

        if let parseResult = UpdateResultParser.parseUpdates(command) {
            self = parseResult
            return
        }

        throw UpdateResultError.output(command)
    }
}

enum UpdateResultError: Error {
    case output(CommandOutput)
}

enum UpdateResultParser {
    static func parseUpdates(_ command: CommandOutput) -> UpdateResult? {
        let updatedCasks = /Updated (?<taps>\d+) taps \((?<casks>.+)\)/
        let newFormulae = /==> New Formulae\n(?<names>[a-z0-9-\n]*)/
        let newCasks = /==> New Casks\n(?<names>[a-z0-9-\n]*)/
        let outdatetFormulae = /==> Outdated Formulae\n(?<names>[a-z0-9-\n]*)/
        let outdatedCasks = /==> Outdated Casks\n(?<names>[a-z0-9-\n]*)/

        let outErrString = command.outErrString

        guard let updatedCasksMatch = outErrString.firstMatch(of: updatedCasks) else {
            return nil
        }

        let newFormulaeMatch = outErrString.firstMatch(of: newFormulae)?
            .output.names.split(separator: "\n") ?? []
        let newCasksMatch = outErrString.firstMatch(of: newCasks)?
            .output.names.split(separator: "\n") ?? []
        let outdatetFormulaeMatch = outErrString.firstMatch(of: outdatetFormulae)?
            .output.names.split(separator: "\n") ?? []
        let outdatedCasksMatch = outErrString.firstMatch(of: outdatedCasks)?
            .output.names.split(separator: "\n") ?? []

        let casks = updatedCasksMatch.output.casks
            .split(separator: ", ")
            .flatMap {
                $0.split(separator: " and ")
            }

        guard !newFormulaeMatch.isEmpty || !newCasksMatch.isEmpty || !outdatetFormulaeMatch
            .isEmpty || !outdatedCasksMatch.isEmpty
        else {
            return nil
        }

        return UpdateResult.updated(
            updatedTaps: updatedCasksMatch.output.taps,
            updatedCasks: casks,
            newFormulae: newFormulaeMatch,
            newCasks: newCasksMatch,
            outdatedFormulae: outdatetFormulaeMatch,
            outdatedCasks: outdatedCasksMatch
        )
    }
}
