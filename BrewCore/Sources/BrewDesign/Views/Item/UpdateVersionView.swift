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

  init(package: PackageInfo) {
    self.package = package
  }

  private var versions: String {
    package.versions?.map {
      $0.description
    }.joined(separator: ", ") ?? ""
  }

  var attributedString: AttributedString {
    let oldVersion = AttributedString("\(versions) < ")
    var newVersion = AttributedString("\(package.versionsStable?.description ?? "")")
    newVersion.font = .body.monospaced().bold()
    return oldVersion + newVersion
  }

  var body: some View {
    if let versionsStable = package.versionsStable, package.outdated {
      HStack {
        Text(attributedString)
      }.font(.body.monospaced())
    }
  }
}
