//
//  UpdateState.swift
//  
//
//  Created by Tomas Harkema on 06/10/2023.
//

import Foundation

public enum UpdateState {
    case updated(UpdateResult)
    case synced
}

public enum PackageState {
    case executed
    case updated
}
