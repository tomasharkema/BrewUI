//
//  AllVersionsView.swift
//
//
//  Created by Tomas Harkema on 13/10/2023.
//

import BrewShared
import SwiftUI

struct AllVersionsView: View {
  private let package: PackageInfo

  init(package: PackageInfo) {
    self.package = package
  }

  var body: some View {
    if let versions = package.versions {
      HStack {
        ForEach(Array(versions)) { version in
          Text("\(version.description)")
        }
      }.font(.body.monospaced())
    }
  }
}
