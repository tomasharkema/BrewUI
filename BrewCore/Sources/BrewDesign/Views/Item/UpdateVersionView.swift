//
//  UpdateVersionView.swift
//  
//
//  Created by Tomas Harkema on 13/10/2023.
//

import BrewShared
import SwiftUI

struct UpdateVersionView: View {
  private let package: PackageInfo
  private let newestVersion: Version?

  init(package: PackageInfo) {
    self.package = package

    self.newestVersion = package.versions?.sorted().last
  }

  var body: some View {
    if let newestVersion, let versionsStable = package.versionsStable {
      HStack {
        Text("\(newestVersion.description) > \(versionsStable.description)")
      }.font(.body.monospaced())
    }
  }
}
