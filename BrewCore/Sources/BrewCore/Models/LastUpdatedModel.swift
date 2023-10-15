//
//  LastUpdatedModel.swift
//
//
//  Created by Tomas Harkema on 14/10/2023.
//

import Foundation
import SwiftData

@Model
public final class LastUpdatedModel {

  @Attribute
  public private(set) var updatedDate: Date

  @Attribute(.unique)
  public private(set) var updatedHashValue: String

  init(updatedDate: Date, updatedHashValue: String) {
    self.updatedDate = updatedDate
    self.updatedHashValue = updatedHashValue
  }
}
