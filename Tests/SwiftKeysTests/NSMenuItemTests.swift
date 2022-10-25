//===----------------------------------------------------------------------===//
//
// NSMenuItemTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class NSMenuItemTests: TestCase {
  var mostRecentHandler: Int?
  
  let command = KeyCommand(name: "Test")
  lazy var observation1 = command.observe(.keyDown) { self.mostRecentHandler = 1 }
  lazy var observation2 = command.observe(.keyDown) { self.mostRecentHandler = 2 }
  lazy var observation3 = command.observe(.keyDown) { self.mostRecentHandler = 3 }
  
  func testObservations() {
    let item = NSMenuItem()
    XCTAssert(item.observations.isEmpty)
    item.observations = [
      .init(observation1),
      .init(observation2),
      .init(observation3),
    ]
    XCTAssert(item.observations.count == 3)
    XCTAssert(item.observations.contains(.init(observation2)))
    item.observations.remove(.init(observation2))
    XCTAssert(!item.observations.contains(.init(observation2)))
  }
  
  func testHandler() {
    let item = NSMenuItem()
    for n in 0..<3 {
      item.setKeyCommand(command) { self.mostRecentHandler = n }
      item.handler?()
      XCTAssert(mostRecentHandler == n)
    }
  }
}
