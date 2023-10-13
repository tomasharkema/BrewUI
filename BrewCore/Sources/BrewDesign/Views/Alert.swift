//
//  Alert.swift
//  BrewUI
//
//  Created by Tomas Harkema on 07/09/2023.
//

import BrewShared
import Processed
import SwiftUI

public extension View {
  func errorAlert(error: Binding<(any Error)?>, buttonTitle: String = "OK") -> some View {
    let localizedAlertError = LocalizedAlertError(error: error.wrappedValue)
    return alert(
      isPresented: .constant(localizedAlertError != nil),
      error: localizedAlertError
    ) { _ in
      Button(buttonTitle) {
        error.wrappedValue = nil
      }
    } message: { error in
      Text(error.recoverySuggestion ?? "")
    }
  }

  func errorAlert(
    state: LoadableState<UpdateState>,
    buttonTitle: String = "OK"
  ) -> some View {
    errorAlert(error: .constant(state.error), buttonTitle: buttonTitle)
  }
}

struct LocalizedAlertError: LocalizedError {
  let underlyingError: any LocalizedError
  var errorDescription: String? {
    underlyingError.errorDescription
  }

  var recoverySuggestion: String? {
    underlyingError.recoverySuggestion
  }

  init?(error: (any Error)?) {
    guard let localizedError = error as? (any LocalizedError) else { return nil }
    underlyingError = localizedError
  }
}
