//
//  Alert.swift
//  BrewUI
//
//  Created by Tomas Harkema on 07/09/2023.
//

import SwiftUI

extension View {
    @ViewBuilder
    func alert(error: Binding<Error?>) -> some View {
        self.alert(Text("Error"), isPresented: error.map { $0 != nil }, presenting: error.wrappedValue) { error in
            Text("Error: \(String(describing: error))")
            Button("OK", role: .cancel) { }
        }
    }
}
