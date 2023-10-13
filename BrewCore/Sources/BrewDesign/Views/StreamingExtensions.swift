//
//  StreamingExtensions.swift
//
//
//  Created by Tomas Harkema on 11/09/2023.
//

import BrewShared
import Foundation

public extension StreamElement {
  var attributedString: AttributedString {
    switch level {
    case .dev:
      var attr = AttributedString(rawEntry)
      attr.foregroundColor = .blue
      return attr

    case .err:
      var attr = AttributedString(rawEntry)
      attr.foregroundColor = .red
      return attr

    case .out:
      let attr = AttributedString(rawEntry)
      return attr
    }
  }
}

public extension CommandOutput {
  var attributed: AttributedString {
    stream.attributed
  }
}

extension StreamStreamingAndTask {
  var attributed: AttributedString {
    stream.attributed
  }
}

extension [StreamElement] {
  var attributed: AttributedString {
    reduce(into: AttributedString()) { prev, new in
      prev += (new.attributedString + AttributedString("\n"))
    }
  }
}
