//===----------------------------------------------------------------------===//
//
// KeyCommandTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox
import XCTest
@testable import SwiftKeys

final class KeyCommandTests: TestCase {
  func testProxySharing1() {
    // This tests to make sure that two key commands with the
    // same name share the same proxy.
    let command1 = KeyCommand(name: "Cheese")
    let command2 = KeyCommand(name: "Cheese")
    XCTAssert(command1.proxy === command2.proxy)
  }
  
  func testProxySharing2() {
    // This tests to make sure that if a command is created with
    // the same name as an existing command, both will assume the
    // value of the newest command.
    let command1 = KeyCommand(name: "Balloon", key: .b, modifiers: [.command])
    let command2 = KeyCommand(name: "Balloon", key: .l, modifiers: [.option])
    XCTAssert(command1.proxy === command2.proxy)
    XCTAssert(command1.proxy.key == .l)
    XCTAssert(command1.proxy.modifiers == [.option])
    XCTAssertEqual(command1, command2)
  }
  
  func testEnable() {
    let command = KeyCommand(name: "Soup", key: .a, modifiers: .option, .shift)
    
    XCTAssert(!command.isEnabled)
    command.observe(.keyDown) { }
    XCTAssert(command.isEnabled)
    command.disable()
    XCTAssert(!command.isEnabled)
    
    XCTAssertNotNil(command.key)
    XCTAssert(!command.modifiers.isEmpty)
    
    command.remove()
    
    XCTAssertNil(command.key)
    XCTAssert(command.modifiers.isEmpty)
  }
  
  func testObservation() {
    var didRunObservation = false
    let observation = KeyCommand.Observation(eventType: .keyDown) {
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
    var lastRunEventType: KeyCommand.EventType?
    let command = KeyCommand(name: "SomeName")
    
    let keyDownObservation = command.observe(.keyDown) {
      lastRunEventType = .keyDown
    }
    
    let keyUpObservation = command.observe(.keyUp) {
      lastRunEventType = .keyUp
    }
    
    XCTAssertNil(lastRunEventType)
    
    command.runHandlers(for: .keyDown)
    XCTAssertEqual(lastRunEventType, .keyDown)
    
    command.runHandlers(for: .keyUp)
    XCTAssertEqual(lastRunEventType, .keyUp)
    
    lastRunEventType = nil
    
    command.removeObservations([keyDownObservation, keyUpObservation])
    
    command.runHandlers(for: .keyDown)
    command.runHandlers(for: .keyUp)
    
    XCTAssertNil(lastRunEventType)
  }
  
  func testRemoveNonSpecificObservations() {
    var lastRunEventType: KeyCommand.EventType?
    let command = KeyCommand(name: "SomeName")
    
    command.observe(.keyDown) {
      lastRunEventType = .keyDown
    }
    
    command.observe(.keyUp) {
      lastRunEventType = .keyUp
    }
    
    XCTAssertNil(lastRunEventType)
    
    command.runHandlers { $0.eventType == .keyDown }
    XCTAssertEqual(lastRunEventType, .keyDown)
    
    command.runHandlers { $0.eventType == .keyUp }
    XCTAssertEqual(lastRunEventType, .keyUp)
    
    lastRunEventType = nil
    
    command.removeObservations { $0.eventType == .keyUp }
    
    command.runHandlers(for: .keyUp)
    XCTAssertNil(lastRunEventType)
    
    command.runHandlers(for: .keyDown)
    XCTAssertEqual(lastRunEventType, .keyDown)
  }
  
  func testRemoveFirstObservation() {
    enum RunInfo {
      case firstKeyDown
      case secondKeyDown
      case firstKeyUp
    }
    
    var runInfo = [RunInfo]()
    let command = KeyCommand(name: "SomeName")
    
    command.observe(.keyDown) {
      runInfo.append(.firstKeyDown)
    }
    
    command.observe(.keyDown) {
      runInfo.append(.secondKeyDown)
    }
    
    command.observe(.keyUp) {
      runInfo.append(.firstKeyUp)
    }
    
    XCTAssertTrue(runInfo.isEmpty)
    
    command.runHandlers(for: .keyDown)
    XCTAssertEqual(runInfo.count, 2)
    XCTAssertEqual(runInfo[0], .firstKeyDown)
    XCTAssertEqual(runInfo[1], .secondKeyDown)
    
    command.runHandlers(for: .keyUp)
    XCTAssertEqual(runInfo.count, 3)
    XCTAssertEqual(runInfo[2], .firstKeyUp)
    
    runInfo.removeAll()
    
    command.removeFirstObservation { $0.eventType == .keyDown }
    
    command.runHandlers(for: .keyDown)
    XCTAssertEqual(runInfo.count, 1)
    XCTAssertEqual(runInfo[0], .secondKeyDown)
  }
  
  func testRemoveAllObservations() {
    var lastRunEventType: KeyCommand.EventType?
    let command = KeyCommand(name: "SomeName")
    
    command.observe(.keyDown) {
      lastRunEventType = .keyDown
    }
    
    command.observe(.keyUp) {
      lastRunEventType = .keyUp
    }
    
    XCTAssertNil(lastRunEventType)
    
    command.runHandlers(for: .keyDown)
    XCTAssertEqual(lastRunEventType, .keyDown)
    
    command.runHandlers(for: .keyUp)
    XCTAssertEqual(lastRunEventType, .keyUp)
    
    lastRunEventType = nil
    
    command.removeAllObservations()
    
    command.runHandlers(for: .keyDown)
    command.runHandlers(for: .keyUp)
    
    XCTAssertNil(lastRunEventType)
  }
  
  func testSystemReserved() {
    XCTAssertTrue(KeyCommand.isReservedBySystem(key: .escape, modifiers: [.command]))
    XCTAssertFalse(KeyCommand.isReservedBySystem(key: .space, modifiers: [.control]))
  }
  
  func testCarbonModifiers() {
    let modifiers: [KeyCommand.Modifier] = [.control, .shift, .command]
    let carbonModifiers = modifiers.carbonFlags
    let recreatedModifiers = [KeyCommand.Modifier](carbonModifiers: .init(carbonModifiers)) ?? []
    XCTAssert(modifiers.allSatisfy { recreatedModifiers.contains($0) })
  }
  
  func testModifiersToNSEventFlags() {
    let pairs: [(NSEvent.ModifierFlags, KeyCommand.Modifier)] = [
      (.control, .control),
      (.option, .option),
      (.shift, .shift),
      (.command, .command),
    ]
    var nsEventFlags = NSEvent.ModifierFlags()
    var correctModifiers = [KeyCommand.Modifier]()
    for pair in pairs {
      nsEventFlags.insert(pair.0)
      correctModifiers.append(pair.1)
      XCTAssertEqual(nsEventFlags.commandModifiers, correctModifiers)
    }
  }
}
