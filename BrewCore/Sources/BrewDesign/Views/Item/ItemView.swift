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
//            Text(package.nameTapAttributedString(isInstalled: package.installedVersion != nil))

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

//
// private extension PackageInfo {
//    func nameAttributedString(size: CGFloat = 12, isInstalled: Bool) -> AttributedString {
//        var a = AttributedString(identifier.name)
//        a.font = .monospacedSystemFont(ofSize: size, weight: isInstalled ? .bold : .light)
//        a.foregroundColor = .foreground
//        return a
//    }
//
//    func tapAttributedString(size: CGFloat = 12) -> AttributedString {
//        var a = AttributedString(identifier.tap)
//        a.foregroundColor = .gray
//        a.font = .monospacedSystemFont(ofSize: size, weight: .ultraLight)
//        return a
//    }
//
//    func slashAttributedString(size: CGFloat = 12) -> AttributedString {
//        var a = AttributedString("/")
//        a.foregroundColor = .gray
//        a.font = .monospacedSystemFont(ofSize: size, weight: .ultraLight)
//        return a
//    }
//
//    func nameTapAttributedString(size: CGFloat = 12, isInstalled: Bool) -> AttributedString {
//        tapAttributedString(size: size) + slashAttributedString(size: size) + nameAttributedString(size: size, isInstalled: isInstalled)
//    }
// }
