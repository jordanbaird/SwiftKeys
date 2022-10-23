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
    
    [observation].performObservations(matching: .init(ref))
    
    XCTAssertFalse(didRunObservation)
  }
  
  func testRemoveSpecificObservations() {
    var lastRunEventType: KeyEvent.EventType?
    let event = KeyEvent(name: "SomeName")
    
    let keyDownObservation = event.observe(.keyDown) {
      lastRunEventType = .keyDown
    }
    
    let keyUpObservation = event.observe(.keyUp) {
      lastRunEventType = .keyUp
    }
    
    XCTAssertNil(lastRunEventType)
    
    event.runHandlers(for: .keyDown)
    XCTAssertEqual(lastRunEventType, .keyDown)
    
    event.runHandlers(for: .keyUp)
    XCTAssertEqual(lastRunEventType, .keyUp)
    
    lastRunEventType = nil
    
    event.removeObservations([keyDownObservation, keyUpObservation])
    
    event.runHandlers(for: .keyDown)
    event.runHandlers(for: .keyUp)
    
    XCTAssertNil(lastRunEventType)
  }
  
  func testRemoveNonSpecificObservations() {
    var lastRunEventType: KeyEvent.EventType?
    let event = KeyEvent(name: "SomeName")
    
    event.observe(.keyDown) {
      lastRunEventType = .keyDown
    }
    
    event.observe(.keyUp) {
      lastRunEventType = .keyUp
    }
    
    XCTAssertNil(lastRunEventType)
    
    event.runHandlers { $0.eventType == .keyDown }
    XCTAssertEqual(lastRunEventType, .keyDown)
    
    event.runHandlers { $0.eventType == .keyUp }
    XCTAssertEqual(lastRunEventType, .keyUp)
    
    lastRunEventType = nil
    
    event.removeObservations { $0.eventType == .keyUp }
    
    event.runHandlers(for: .keyUp)
    XCTAssertNil(lastRunEventType)
    
    event.runHandlers(for: .keyDown)
    XCTAssertEqual(lastRunEventType, .keyDown)
  }
  
  func testRemoveFirstObservation() {
    enum RunInfo {
      case firstKeyDown
      case secondKeyDown
      case firstKeyUp
    }
    
    var runInfo = [RunInfo]()
    let event = KeyEvent(name: "SomeName")
    
    event.observe(.keyDown) {
      runInfo.append(.firstKeyDown)
    }
    
    event.observe(.keyDown) {
      runInfo.append(.secondKeyDown)
    }
    
    event.observe(.keyUp) {
      runInfo.append(.firstKeyUp)
    }
    
    XCTAssertTrue(runInfo.isEmpty)
    
    event.runHandlers(for: .keyDown)
    XCTAssertEqual(runInfo.count, 2)
    XCTAssertEqual(runInfo[0], .firstKeyDown)
    XCTAssertEqual(runInfo[1], .secondKeyDown)
    
    event.runHandlers(for: .keyUp)
    XCTAssertEqual(runInfo.count, 3)
    XCTAssertEqual(runInfo[2], .firstKeyUp)
    
    runInfo.removeAll()
    
    event.removeFirstObservation { $0.eventType == .keyDown }
    
    event.runHandlers(for: .keyDown)
    XCTAssertEqual(runInfo.count, 1)
    XCTAssertEqual(runInfo[0], .secondKeyDown)
  }
  
  func testRemoveAllObservations() {
    var lastRunEventType: KeyEvent.EventType?
    let event = KeyEvent(name: "SomeName")
    
    event.observe(.keyDown) {
      lastRunEventType = .keyDown
    }
    
    event.observe(.keyUp) {
      lastRunEventType = .keyUp
    }
    
    XCTAssertNil(lastRunEventType)
    
    event.runHandlers(for: .keyDown)
    XCTAssertEqual(lastRunEventType, .keyDown)
    
    event.runHandlers(for: .keyUp)
    XCTAssertEqual(lastRunEventType, .keyUp)
    
    lastRunEventType = nil
    
    event.removeAllObservations()
    
    event.runHandlers(for: .keyDown)
    event.runHandlers(for: .keyUp)
    
    XCTAssertNil(lastRunEventType)
  }
  
  func testSystemReserved() {
    XCTAssertTrue(KeyEvent.isReservedBySystem(key: .escape, modifiers: [.command]))
    XCTAssertFalse(KeyEvent.isReservedBySystem(key: .space, modifiers: [.control]))
  }
}
