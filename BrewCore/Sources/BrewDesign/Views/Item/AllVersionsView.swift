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

  private var versions: String {
    package.versions?.map {
      $0.description
    }.joined(separator: ", ") ?? ""
  }

  var body: some View {
    if package.versions != nil {
      Text("\(versions)").font(.body.monospaced())
    }
  }
}
