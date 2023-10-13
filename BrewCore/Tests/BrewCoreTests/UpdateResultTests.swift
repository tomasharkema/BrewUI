//
//  UpdateResultTests.swift
//
//
//  Created by Tomas Harkema on 11/09/2023.
//

@testable import BrewCore
import Foundation
import PowerAssert
import XCTest

final class UpdateResultTests: XCTestCase {
  func testAlreadyUpToDateOut() throws {
    let cmd = CommandOutput(stream: .out("Already up-to-date"))
    let result = try UpdateResult(cmd)
    #assert(result == .alreadyUpToDate)
  }

  func testAlreadyUpToDateErr() throws {
    let cmd = CommandOutput(stream: .err("Already up-to-date"))
    let result = try UpdateResult(cmd)
    #assert(result == .alreadyUpToDate)
  }

  func testTestString() throws {
    let result = try UpdateResult(CommandOutput(stream: .err(testString)))

    guard case let .updated(
      updatedTaps, updatedCasks,
      newFormulae, newCasks, outdatedFormulae, outdatedCasks
    ) = result else {
      XCTFail()
      return
    }

    #assert(updatedTaps == "3")
    #assert(updatedCasks[0] == "homebrew/cask-versions")
    #assert(updatedCasks[1] == PackageIdentifier.core)
    #assert(updatedCasks[2] == "homebrew/cask")

    #assert(newFormulae.count == 4)
    #assert(newCasks.count == 2)
    #assert(outdatedFormulae.count == 8)
    #assert(outdatedCasks.count == 5)

    #assert(newFormulae.contains("vulkan-utility-libraries"))
    #assert(newCasks.contains("draw-things"))
    #assert(outdatedFormulae.contains("cryfs"))
    #assert(outdatedCasks.contains("1password-cli"))
  }
}

let testString = """
Updated 3 taps (homebrew/cask-versions, homebrew/core and homebrew/cask).
==> New Formulae
cargo-docset
cyclonedx-gomod
cyclonedx-python
vulkan-utility-libraries
==> New Casks
draw-things
playcover-community-beta
==> Outdated Formulae
cryfs
glib
gobject-introspection
harfbuzz
heroku
node
pygobject3
rtmpdump
==> Outdated Casks
1password-cli
android-platform-tools
grandperspective
rar
swiftformat-for-xcode

You have 8 outdated formulae and 5 outdated casks installed.
You can upgrade them with brew upgrade
or list them with brew outdated.
"""
