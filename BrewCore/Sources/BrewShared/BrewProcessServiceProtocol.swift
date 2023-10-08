//
//  BrewProcessServiceProtocol.swift
//  
//
//  Created by Tomas Harkema on 07/10/2023.
//

import Foundation

public protocol BrewProcessServiceProtocol {

    func stream(command: BrewCommand) async throws -> StreamStreamingAndTask

    func infoFromBrew(command: BrewCommand.InfoCommand) async throws -> [InfoResult]

    func infoFormulaInstalled() async throws -> [InfoResult]

    func taps() async throws -> [String]

    func tap(name: String) async throws -> [TapInfo]

    func searchFormula(query: String) async throws -> [PackageIdentifier]

    func infoFormula(package: PackageIdentifier) async throws -> [InfoResult]

    func update() async throws -> UpdateResult

    func listFormula() async throws -> [ListResult]
}
