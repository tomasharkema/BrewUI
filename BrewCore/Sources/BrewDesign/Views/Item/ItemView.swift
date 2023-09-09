//
//  ItemView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 09/05/2023.
//

import SwiftUI
import BrewCore
import BrewShared

struct ItemView: View {
    private let package: PackageInfo
    private let showInstalled: Bool

    init(package: PackageInfo, showInstalled: Bool) {
        self.package = package
        self.showInstalled = showInstalled
    }

    @ViewBuilder
    private func version() -> some View {
        if package.outdated, let installedVersion = package.installedVersion, let stable = package.versionsStable {
            Text("\(installedVersion) > \(stable)").font(.body.monospaced())
        } else {
            if let version = package.installedVersion {
                Text(version).font(.body.monospaced())
            } else if let stable = package.versionsStable {
                Text(stable).font(.body.monospaced())
            }
        }
    }

    var body: some View {
        HStack {
//            Text(package.nameTapAttributedString(isInstalled: package.installedVersion != nil))

            VStack(alignment: .leading) {
                Text((try? package.identifier.name) ?? "")
                    .font(.body.monospaced())
                    .foregroundColor(PublicColor.foreground)
                Text((try? package.identifier.tap) ?? "")
                    .font(.body.monospaced())
                    .foregroundColor(.gray)
                version()
            }

            Spacer()
            version()
//            if let installed = info.installed.first {
//                if showInstalled {
//                    Text("INSTALLED").font(.body.monospaced()) // .bold()//.background(Color.accentColor).cornerRadius(5)
//                }
//                if installed.installed_as_dependency {
//                    Text("DEP").font(.body.monospaced()) // .bold()//.background(Color.accentColor).cornerRadius(5)
//                }
//            }
            
            //      Text(info.name).font(.body.monospaced())

        }
    }
}

//
//private extension PackageInfo {
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
//}
