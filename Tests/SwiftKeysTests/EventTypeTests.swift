//===----------------------------------------------------------------------===//
//
// EventTypeTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox
import XCTest
@testable import SwiftKeys

final class EventTypeTests: TestCase {
  func testInitWithInteger() {
    let typePressed = KeyCommand.EventType(kEventHotKeyPressed)
    let typeReleased = KeyCommand.EventType(kEventHotKeyReleased)
    let typeNone = KeyCommand.EventType(kEventHotKeyNoOptions)
    XCTAssertNotNil(typePressed)
    XCTAssertNotNil(typeReleased)
    XCTAssertNil(typeNone)
  }
  
  func testInitWithEventRef() {
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
    
    // Use that to create an EventType. If all goes right, this should fail.
    let nilType = KeyCommand.EventType(ref)
    XCTAssertNil(nilType)
  }
}
