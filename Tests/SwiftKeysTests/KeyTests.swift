//===----------------------------------------------------------------------===//
//
// KeyTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class KeyTests: XCTestCase {
  func testInitRawValue() {
    for key in KeyEvent.Key.allCases {
      XCTAssertEqual(KeyEvent.Key(key.rawValue), key)
      XCTAssertEqual(KeyEvent.Key(key.stringValue)?.stringValue, key.stringValue)
    }
  }
}
