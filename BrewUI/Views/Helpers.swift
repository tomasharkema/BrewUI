//
//  Helpers.swift
//  BrewUI
//
//  Created by Tomas Harkema on 05/05/2023.
//

import SwiftUI

extension String: Identifiable {
    public var id: Int {
        hashValue
    }
}

extension ListResult: Identifiable {
    var id: Int {
        hashValue
    }
}

extension InfoResult: Identifiable {
    var id: Int {
        hashValue
    }
}
