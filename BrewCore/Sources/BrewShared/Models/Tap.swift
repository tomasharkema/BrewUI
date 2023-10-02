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

    public init(name: String) {
        self.name = name
    }
}
