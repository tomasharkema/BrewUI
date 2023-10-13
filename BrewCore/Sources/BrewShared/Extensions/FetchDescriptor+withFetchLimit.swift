//
//  FetchDescriptor+withFetchLimit.swift
//
//
//  Created by Tomas Harkema on 06/09/2023.
//

import SwiftData

public extension FetchDescriptor {
  func withFetchLimit(_ fetchLimit: Int?) -> FetchDescriptor {
    var new = self
    new.fetchLimit = fetchLimit
    return new
  }
}
