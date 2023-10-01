//
//  PackageTable.swift
//  BrewUI
//
//  Created by Tomas Harkema on 03/09/2023.
//

import BrewCore
import BrewShared
import SwiftData
import SwiftUI

// swiftlint:disable type_name

// #if DEBUG
//    public struct _PackageTable: View {
//        @Query(
//            FetchDescriptor<PackageCache>(sortBy: [SortDescriptor(\.sortValue)])
//                .withFetchLimit(BrewCache.globalFetchLimit)
//        )
//        private var all: [PackageCache]
//
//        public init() {}
//
//        public var body: some View {
//            Table(all) {
//                TableColumn("Package", value: \.baseName)
//                TableColumn("Tap", value: \.tap)
//                TableColumn("Installed Version") { package in
//                    Text(package.installedVersion ?? "")
//                }
//                TableColumn("Latest Version", value: \.versionsStable)
////            TableColumn("Description", value: \.desc)
//            }
//            .font(.body.monospaced())
//        }
//    }
// #endif

// swiftlint:enable type_name
