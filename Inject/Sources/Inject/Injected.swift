//
//  Injected.swift
//
//
//  Created by Tomas Harkema on 05/10/2023.
//

import Foundation
import SwiftUI

@propertyWrapper
public class Injected<T> {
  private let keyPath: WritableKeyPath<InjectedValues, T>

  public var wrappedValue: T {
    get { InjectedValues[keyPath] }
    set { InjectedValues[keyPath] = newValue }
  }

  public init(_ keyPath: WritableKeyPath<InjectedValues, T>) {
    self.keyPath = keyPath
  }
}

extension Injected: DynamicProperty where T: ObservableObject {}
