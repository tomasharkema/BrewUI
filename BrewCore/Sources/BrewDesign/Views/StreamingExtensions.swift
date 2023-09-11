//
//  StreamingExtensions.swift
//  
//
//  Created by Tomas Harkema on 11/09/2023.
//

import Foundation
import BrewShared
import BrewCore

extension CommandOutput {
    public var attributed: AttributedString {
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
