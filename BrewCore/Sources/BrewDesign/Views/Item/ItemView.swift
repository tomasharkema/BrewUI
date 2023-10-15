//
//  ItemView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import BrewShared
import SwiftUI

struct ItemView: View {
  private let package: PackageInfo
  private let showInstalled: Bool

  init(package: PackageInfo, showInstalled: Bool) {
    self.package = package
    self.showInstalled = showInstalled
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text((try? package.identifier.name) ?? "")
          .font(.body.monospaced())
          .foregroundColor(Color(.foregroundTint))
        Text((try? package.identifier.tap) ?? "")
          .font(.body.monospaced())
          .foregroundColor(.gray)
        AllVersionsView(package: package)
      }

      Spacer()
      UpdateVersionView(package: package)
    }
  }
}
