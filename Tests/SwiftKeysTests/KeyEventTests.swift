//===----------------------------------------------------------------------===//
//
// KeyEventTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox
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
  
  func testEnable() {
    let event = KeyEvent(name: "Soup", key: .a, modifiers: .option, .shift)
    
    XCTAssert(!event.isEnabled)
    event.observe(.keyDown) { }
    XCTAssert(event.isEnabled)
    event.disable()
    XCTAssert(!event.isEnabled)
    
    XCTAssertNotNil(event.key)
    XCTAssert(!event.modifiers.isEmpty)
    
    event.remove()
    
    XCTAssertNil(event.key)
    XCTAssert(event.modifiers.isEmpty)
  }
  
  func testObservation() {
    var didRunObservation = false
    let observation = KeyEvent.Observation(eventType: .keyDown) {
      didRunObservation = true
    }
    
    // Create an arbitrary CGEvent that we know won't be key up or key down.
    let cgEvent = CGEvent(
      scrollWheelEvent2Source: .init(stateID: .hidSystemState),
      units: .pixel,
      wheelCount: 1,
      wheel1: 0,
      wheel2: 0,
      wheel3: 0)!
    
    // Get its NSEvent equivalent.
    let nsEvent = NSEvent(cgEvent: cgEvent)!
    
    // Use it to create an EventRef.
    let ref = EventRef(nsEvent.eventRef)!
    
    observation.tryToPerform(with: ref)
    
    XCTAssertFalse(didRunObservation)
  }
}
