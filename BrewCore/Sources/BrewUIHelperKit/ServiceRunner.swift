//
//  ServiceRunner.swift
//
//
//  Created by Tomas Harkema on 07/10/2023.
//

import BrewHelperXPC
import Foundation

public enum ServiceRunner {
  public static func run() {
    let listener = BrewProtocolServiceXPCListener(xpc: .service)

    listener.newConnectionHandler = {
      $0.exportedObject = BrewProtocolServiceImpl()
      $0.resume()
      return true
    }

    listener.resume()

    RunLoop.main.run()
  }
}
