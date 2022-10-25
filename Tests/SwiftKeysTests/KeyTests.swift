//===----------------------------------------------------------------------===//
//
// KeyTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class KeyTests: TestCase {
  func testInitRawValue() {
    for key in KeyCommand.Key.allCases {
      XCTAssertEqual(KeyCommand.Key(key.rawValue), key)
      XCTAssertEqual(KeyCommand.Key(key.stringValue)?.stringValue, key.stringValue)
    }
  }
}
