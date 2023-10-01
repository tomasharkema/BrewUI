//
//  CommandResult.swift
//
//
//  Created by Tomas Harkema on 10/09/2023.
//

import Foundation

public struct CommandOutput {
    public let stream: [StreamElement]

    var outErrString: String {
        stream.outErrString
    }

    var outString: String {
        stream.outString
    }
}
