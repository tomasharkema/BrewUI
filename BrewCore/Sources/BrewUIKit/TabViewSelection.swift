//
//  TabViewSelection.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

import Foundation

enum TabViewSelection: String {
    case installed
    case updates
    case all
    case table
    case searchResult
}

extension TabViewSelection: Hashable, Equatable { }
