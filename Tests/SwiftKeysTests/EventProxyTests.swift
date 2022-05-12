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
    // This tests to ensure that events are installed properly,
    // and that if the `install()` method returns an error, it
    // is accurate in that it truly did not install.
    let event = KeyEvent(name: "AnEvent", key: .space, modifiers: .command)
    XCTAssert(!EventProxy.isInstalled)
    if event.proxy.install() == noErr {
      XCTAssert(EventProxy.isInstalled)
    } else {
      XCTAssert(!EventProxy.isInstalled)
    }
  }
  
  func testRegisterAndUnregister() {
    // This tests to ensure that proxies are registered and
    // unregistered properly.
    let event = KeyEvent(name: "AnEvent", key: .comma, modifiers: [.option])
    XCTAssert(!event.proxy.isRegistered)
    event.proxy.register()
    XCTAssert(event.proxy.isRegistered)
    event.proxy.unregister()
    XCTAssert(!event.proxy.isRegistered)
  }
  
  func testObserveRegistrationState() {
    // This makes sure that calling `observeRegistrationState(_:)`
    // stores the handler that is provided.
    let event = KeyEvent(name: "AnEvent")
    XCTAssert(event.proxy.registrationStateObservations.isEmpty)
    event.proxy.observeRegistrationState { }
    XCTAssert(event.proxy.registrationStateObservations.count == 1)
  }
  
  func testResetRegistration() {
    let event = KeyEvent(name: "AnEvent", key: .comma, modifiers: [.option])
    XCTAssert(!event.proxy.isRegistered)
    event.proxy.register()
    XCTAssert(event.proxy.isRegistered)
    event.proxy.resetRegistration(shouldReregister: true)
    XCTAssert(event.proxy.isRegistered)
    event.proxy.resetRegistration(shouldReregister: false)
    XCTAssert(!event.proxy.isRegistered)
  }
}
