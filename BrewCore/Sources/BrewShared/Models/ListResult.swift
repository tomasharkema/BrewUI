//
//  ListResult.swift
//  BrewUI
//
//  Created by Tomas Harkema on 31/08/2023.
//

import Foundation
import MetaCodable
import SwiftData

public struct ListResult: Hashable, Equatable {
    let name: String
    let version: String
    //  let cask: Bool

    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}
