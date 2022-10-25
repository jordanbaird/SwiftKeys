//===----------------------------------------------------------------------===//
//
// ObservationTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class ObservationTests: TestCase {
  var handler1WasCalled = false
  var handler2WasCalled = false
  lazy var o1 = KeyCommand.Observation(eventType: .keyDown) { self.handler1WasCalled = true }
  lazy var o2 = KeyCommand.Observation(eventType: .keyDown) { self.handler2WasCalled = true }
  
  func testID() {
    XCTAssertNotEqual(o1.id, o2.id)
  }
  
  func testHandlers() {
    XCTAssertFalse(handler1WasCalled)
    XCTAssertFalse(handler2WasCalled)
    o1.handler()
    o2.handler()
    XCTAssertTrue(handler1WasCalled)
    XCTAssertTrue(handler2WasCalled)
  }
  
  func testHashValues() {
    XCTAssertNotEqual(o1.hashValue, o2.hashValue)
  }
  
  func testEquatable() {
    XCTAssertNotEqual(o1, o2)
  }
}
