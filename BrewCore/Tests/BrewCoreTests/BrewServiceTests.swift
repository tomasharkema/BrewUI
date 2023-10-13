//
//  BrewServiceTests.swift
//
//
//  Created by Tomas Harkema on 09/09/2023.
//

@testable import BrewCore
import BrewShared
import Foundation
import PowerAssert
import XCTest

final class BrewServiceTests: XCTestCase {
  func testParseListVersions() {
    let string = """
    abseil 20230802.0
    wineskin 1.8.4.2
    """

    let list = BrewService.parseListVersions(input: string)

    #assert(list[0] == ListResult(name: "abseil", version: "20230802.0"))
    #assert(list[1] == ListResult(name: "wineskin", version: "1.8.4.2"))
  }
}
