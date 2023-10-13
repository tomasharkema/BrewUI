//
//  TabViewSelection.swift
//
//
//  Created by Tomas Harkema on 01/10/2023.
//

enum TabViewSelection: String {
  case installed
  case updates
  case all
  case taps
  case table
  case searchResult
}

extension TabViewSelection: Hashable, Equatable {}
