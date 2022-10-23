//===----------------------------------------------------------------------===//
//
// EventProxyTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class EventProxyTests: XCTestCase {
  func testInstall() {
    let event = KeyEvent(name: "Event1")
    XCTAssertFalse(EventProxy.isInstalled)
    XCTAssertEqual(event.proxy.install(), noErr)
    XCTAssertTrue(EventProxy.isInstalled)
  }
  
  func testRegisterAndUnregister() {
    var event = KeyEvent(name: "Event2")
    XCTAssertFalse(event.proxy.isRegistered)
    event.proxy.register()
    XCTAssertFalse(event.proxy.isRegistered, """
                   Events with no key or modifiers should not be able \
                   to be registered.
                   """)
    event = KeyEvent(name: "Event2", key: .return, modifiers: .option)
    event.proxy.register()
    XCTAssertTrue(event.proxy.isRegistered, """
                  Calling register() when an event has a key and \
                  modifiers should register the event.
                  """)
    event.proxy.unregister()
    XCTAssertFalse(event.proxy.isRegistered,
                   "Calling unregister() should unregister the event.")
  }
  
  func testObserveRegistrationState() {
    let event = KeyEvent(name: "Event3")
    XCTAssert(event.proxy.registrationStateObservations.isEmpty)
    event.proxy.observeRegistrationState { }
    XCTAssert(event.proxy.registrationStateObservations.count == 1,
              "Calling observeRegistrationState(_:) should store a handler.")
  }
  
  func testResetRegistration() {
    let event = KeyEvent(name: "Event4", key: .comma, modifiers: [.option])
    XCTAssertFalse(event.proxy.isRegistered)
    event.proxy.register()
    XCTAssertTrue(event.proxy.isRegistered)
    event.proxy.unregister(shouldReregister: true)
    XCTAssertTrue(event.proxy.isRegistered)
    event.proxy.unregister(shouldReregister: false)
    XCTAssertFalse(event.proxy.isRegistered)
  }
}
