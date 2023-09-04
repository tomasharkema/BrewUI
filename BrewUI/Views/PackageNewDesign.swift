//
//  PackageNewDesign.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import SwiftUI
import BrewCore
import SwiftData

//struct PackageNewDesign: View {
//    @Binding var selection: PackageIdentifier?
//
//    @Query
//    var all: [PackageCache]
//
//    init(selection: Binding<PackageIdentifier?>) {
//        _selection = selection
//        var fd = FetchDescriptor<PackageCache>(sortBy: [SortDescriptor(\.sortValue)])
//        fd.fetchLimit = BrewCache.globalFetchLimit
//        _all = Query(fd)
//    }
//
//    var body: some View {
//        List(all, selection: $selection) { item in
//            PackageNewDesignItemView(package: item)
//        }
//        .tag(TabViewSelection.newDesign)
//        .tabItem {
//            Text("New Design")
//        }
//    }
//}
//
//struct PackageNewDesignItemView: View {
//    let package: PackageCache
//    
//    @ViewBuilder
//    private func version() -> some View {
//        if package.outdated, let installedVersion = package.installedVersion {
//
//            Text("\(installedVersion) > \(package.versionsStable)").font(.body.monospaced())
//
//        } else {
//            if let version = package.installedVersion {
//                Text(version).font(.body.monospaced())
//            } else {
//                Text(package.versionsStable).font(.body.monospaced())
//            }
//        }
//    }
//
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                HStack {
//                    Text(package.baseName)
//                        .font(.body.monospaced().bold())
//                        .foregroundColor(.foreground)
//                    Text("  ")
//                    version()
//                    Spacer()
//                }
//                Text(package.desc)
//                    .font(.body.monospaced())
//                Text(package.tap)
//                    .font(.body.monospaced())
//                    .foregroundColor(.gray)
//            }
//
//            if package.outdated {
//                VStack {
//                    Button(action: {}, label: {
//                        Text("Update")
//                    })
////                    Text(package.versionsStable)
////                        .font(.body.monospaced())
////                        .foregroundColor(.gray)
//                }
//            } else if let installedVersion = package.installedVersion {
//                VStack {
//                    Button(action: {}, label: {
//                        Text("Uninstall \(installedVersion)")
//                    })
////                    Text(installedVersion)
////                        .font(.body.monospaced())
////                        .foregroundColor(.gray)
//                }
//            } else {
//                VStack {
//                    Button(action: {}, label: {
//                        Text("Install")
//                    })
////                    Text(package.versionsStable)
////                        .font(.body.monospaced())
////                        .foregroundColor(.gray)
//                }
//            }
//        }
//    }
//}
