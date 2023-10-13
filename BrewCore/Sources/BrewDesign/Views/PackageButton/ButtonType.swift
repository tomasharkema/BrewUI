//
//  ButtonType.swift
//
//
//  Created by Tomas Harkema on 02/10/2023.
//

import BrewShared
import SwiftMacros

@AddAssociatedValueVariable
public enum ButtonType {
  case updateAll
  case upgradeAll
  case package(PackageInfo)
}
