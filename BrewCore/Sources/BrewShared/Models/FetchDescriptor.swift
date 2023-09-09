//
//  FetchDescriptor.swift
//
//
//  Created by Tomas Harkema on 06/09/2023.
//

import Foundation
import SwiftData

extension FetchDescriptor {
    public func withFetchLimit(_ fetchLimit: Int?) -> FetchDescriptor {
        var new = self
        new.fetchLimit = fetchLimit
        return new
    }
}
