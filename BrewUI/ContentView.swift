//
//  ContentView.swift
//  BrewUI
//
//  Created by Tomas Harkema on 05/05/2023.
//

import SwiftUI

struct ItemView: View {
  let info: InfoResult
  let showInstalled: Bool

  var body: some View {
    HStack {
      Text(info.full_name).font(.body.monospaced())
      if let installed = info.installed.first {
        if showInstalled {
          Text("INSTALLED").padding(2).bold().background(Color.accentColor).cornerRadius(5)
        }
        if installed.installed_as_dependency {
          Text("DEPENDENCEE").padding(2).bold().background(Color.accentColor).cornerRadius(5)
        }
      }
//      Text(info.name).font(.body.monospaced())
      Spacer()
      if let version = info.installed.first {
        Text(version.version)
      } else if let stable = info.versions.stable {
        Text(stable)
      }
    }
  }
}

enum TabViewSelection: String, Hashable {
  case installed
  case updates
  case all
}

struct ContentView: View {
  @MainActor @State var updates = [InfoResult]()
  @MainActor @State var searchText = ""
  @MainActor @State var searchTextOrNil: String?

  @MainActor @AppStorage("tabviewSelection") var tabviewSelection = TabViewSelection.installed

  @MainActor @State var selectionInstalled = Set<InfoResult>()
  @MainActor @State var selection: InfoResult?

  @ObservedObject var brewService: BrewService = .shared

  @MainActor @State var stream: StreamOutput?

  var body: some View {
    TabView(selection: $tabviewSelection) {
      let val = Array(brewService.cacheInstalledSorted)
      List(val, id: \.self, selection: $selection) { item in
        ItemView(info: item, showInstalled: false)
      }
      .task {
        do {
          _ = try await BrewService.shared.listInstalledItems()
        } catch {
          print(error)
        }
      }
      .tag(TabViewSelection.installed)
      .tabItem {
        Text("Installed Items")
      }

      List(updates, id: \.self, selection: $selection) { item in
        ItemView(info: item, showInstalled: false)
      }
      .task {
        do {
          updates = try await BrewService.shared.outdated()
        } catch {
          print(error)
        }
      }
      .tag(TabViewSelection.updates)
      .tabItem {
        Text("Updates")
      }

      let filtered = brewService.cacheAllSorted.filter { item in
        if let query = searchTextOrNil {
          return item.full_name.contains(query)
        } else {
          return true
        }
      }

      List(filtered, id: \.self, selection: $selection) { item in
        ItemView(info: item, showInstalled: true)
      }
      .task {
        do {
          _ = try await BrewService.shared.listAllItems()
        } catch {
          print(error)
        }
      }
      .tag(TabViewSelection.all)
      .tabItem {
        Text("All Items")
      }
    }
    .sheet(item: $selection, onDismiss: {
      selection = nil
    }) { item in
      ItemDetailView(item: item).padding()
    }
    .searchable(text: $searchText)
    .onChange(of: searchText) {
      if searchText == "" {
        searchTextOrNil = nil
      } else {
        searchTextOrNil = $0
        if tabviewSelection != .all {
          tabviewSelection = .all
        }
      }
    }
    .padding()
  }
}

extension String: Identifiable {
  public var id: Int {
    hashValue
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

extension ListResult: Identifiable {
  var id: Int {
    hashValue
  }
}

extension InfoResult: Identifiable {
  var id: Int {
    hashValue
  }
}

struct ItemDetailView: View {
  @Environment(\.dismiss) var dismiss
//  @State var stream: StreamOutput?
  @ObservedObject var brewService: BrewService = .shared

  @MainActor @State var stream: StreamStreaming?
  @State var done = false
  let item: InfoResult

  var body: some View {
    VStack {
      HStack {
        if let installed = item.installed.first {
          Button("Uninstall \(installed.version)") {
            Task {
              done = false
              defer {
                done = true
              }
              try await BrewService.shared.uninstall(name: item.name)
            }
          }
          if item.outdated {
            Button("Upgrade") {
              Task {
                done = false
                defer {
                  done = true
                }
                try await BrewService.shared.upgrade(name: item.name)
              }
            }
          }
        } else {
          Button("Install") {
            Task {
              done = false
              defer {
                done = true
              }
              try await BrewService.shared.install(name: item.name)
            }
          }
        }

        Button("Close") {
          dismiss()
        }
      }

      HStack(alignment: .firstTextBaseline) {
        Text(item.name).font(.title.monospaced())
        Text(item.versions.stable ?? "").font(.body)
      }

      Text(item.license ?? "").font(.body)
      Text(item.homepage).font(.body)
    }.textSelection(.enabled)

      .onReceive(brewService.$stream) {
        stream = $0
      }
      .sheet(item: $stream) { stream in
        VStack {
          //        if !stream.isStreamingDone {
          //          Button("Cancel") {
          //            self.stream = nil
          //            BrewService.shared.done()
          //          }
          //        }

          ScrollView {
            Text(stream.stream.stream).textSelection(.enabled)
              .multilineTextAlignment(.leading)
              .font(.body.monospaced())
              .padding()
          }
          if stream.stream.isStreamingDone, done {
            Button("Done") {
              self.stream = nil
              BrewService.shared.done()
            }
          } else {
            ProgressView().progressViewStyle(CircularProgressViewStyle())
          }
        }.padding()
          .frame(minWidth: 600, minHeight: 400)
      }
  }
}
