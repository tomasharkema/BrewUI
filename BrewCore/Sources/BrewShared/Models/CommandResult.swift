//
//  CommandResult.swift
//
//
//  Created by Tomas Harkema on 10/09/2023.
//

public struct CommandOutput: Codable, Equatable {
  public let stream: [StreamElement]

  public init(stream: [StreamElement]) {
    self.stream = stream
  }

  public var outErrString: String {
    stream.outErrString
  }

  public var outString: String {
    stream.outString
  }
}
