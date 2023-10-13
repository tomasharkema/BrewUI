//
//  BrewAppMainContainer.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import SwiftUI

public struct BrewAppMainContainer: View {
  @State
  private var dependencies: Dependencies?

  public init() {}

  public var body: some View {
    Group {
      if let dependencies {
        MainTabView()
          .modelContainer(dependencies.modelContainer)
          .environmentObject(dependencies.updateService)
      } else {
        ProgressView()
          .controlSize(.small)
      }
    }.task {
      do {
        if dependencies == nil {
          dependencies = try await Dependencies.shared()
        }
      } catch {
        print(error)
      }
    }
  }
}
