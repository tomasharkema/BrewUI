//
//  Injected.swift
//
//
//  Created by Tomas Harkema on 05/10/2023.
//

import Foundation
import SwiftUI

@propertyWrapper
public class Injected<InjectedType> {
  private let keyPath: WritableKeyPath<InjectedValues, InjectedType>

  public var wrappedValue: InjectedType {
    get { InjectedValues[keyPath] }
    set { InjectedValues[keyPath] = newValue }
  }

  public init(_ keyPath: WritableKeyPath<InjectedValues, InjectedType>) {
    self.keyPath = keyPath
  }
}

extension Injected: DynamicProperty where InjectedType: ObservableObject { }

extension Injected: @unchecked Sendable { }
extension WritableKeyPath: @unchecked Sendable { }
