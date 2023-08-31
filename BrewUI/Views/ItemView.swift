//
//  ItemView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftUI

struct ItemView: View {
  let info: InfoResult
  let showInstalled: Bool

  var body: some View {
    let isInstalled = !info.installed.isEmpty

    HStack {
      Text(info.full_name.rawValue)
        .font(.body.monospaced())
        .foregroundColor(Color(.foreground))
        .fontWeight(isInstalled ? .bold : .regular)

      Spacer()

      if let installed = info.installed.first {
        if showInstalled {
          Text("INSTALLED") // .bold()//.background(Color.accentColor).cornerRadius(5)
        }
        if installed.installed_as_dependency {
          Text("DEP") // .bold()//.background(Color.accentColor).cornerRadius(5)
        }
      }
      //      Text(info.name).font(.body.monospaced())
      if let version = info.installed.first {
        Text(version.version)
      } else if let stable = info.versions.stable {
        Text(stable)
      }
    }
  }
}
