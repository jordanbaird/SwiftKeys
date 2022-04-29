//===----------------------------------------------------------------------===//
//
// KeyEventTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class KeyEventTests: XCTestCase {
  func testProxySharing1() {
    // This tests to make sure that two key events with the same
    // name share the same proxy.
    let event1 = KeyEvent(name: "Cheese")
    let event2 = KeyEvent(name: "Cheese")
    XCTAssert(event1.proxy === event2.proxy)
  }
  
  func testProxySharing2() {
    // This tests to make sure that if an event is created with
    // the same name as an existing event, both will assume the
    // value of the newest event.
    let event1 = KeyEvent(name: "Balloon", key: .b, modifiers: [.command])
    let event2 = KeyEvent(name: "Balloon", key: .l, modifiers: [.option])
    XCTAssert(event1.proxy === event2.proxy)
    XCTAssert(event1.proxy.key == .l)
    XCTAssert(event1.proxy.modifiers == [.option])
    XCTAssertEqual(event1, event2)
  }
}
