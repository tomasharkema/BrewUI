//
//  LoadingState.swift
//
//
//  Created by Tomas Harkema on 07/09/2023.
//

import Foundation
import SwiftMacros

@AddAssociatedValueVariable
public enum LoadingState<Result> {
    case idle
    case loading
    case result(Result)
    case error
}
