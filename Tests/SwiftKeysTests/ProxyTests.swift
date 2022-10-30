//===----------------------------------------------------------------------===//
//
// ProxyTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class ProxyTests: TestCase {
  func testManualInstall() {
    XCTAssertFalse(Proxy.isInstalled)
    assertNoErr(Proxy.install())
    XCTAssertTrue(Proxy.isInstalled)
  }
  
  func testInstall() {
    var command = KeyCommand(name: "Command1")
    XCTAssertFalse(Proxy.isInstalled)
    command = KeyCommand(
      name: "Command1",
      key: .return,
      modifiers: .command, .control)
    command.observe(.keyDown) { }
    XCTAssertTrue(Proxy.isInstalled)
  }
  
  func testRegisterAndUnregister() {
    var command = KeyCommand(name: "Command2")
    XCTAssertFalse(command.proxy.isRegistered)
    command.proxy.register()
    XCTAssertFalse(command.proxy.isRegistered, """
                   Commands with no key or modifiers should not be able \
                   to be registered.
                   """)
    command = KeyCommand(
      name: "Command2",
      key: .return,
      modifiers: .option)
    command.proxy.register()
    XCTAssertTrue(command.proxy.isRegistered, """
                  Calling register() when a command has a key and \
                  modifiers should register the command.
                  """)
    command.proxy.unregister()
    XCTAssertFalse(command.proxy.isRegistered,
                   "Calling unregister() should unregister the command.")
  }
  
  func testObserveRegistrationState() {
    let command = KeyCommand(name: "Command3")
    XCTAssert(command.proxy.registrationStateObservations.isEmpty)
    command.proxy.observeRegistrationState { }
    XCTAssertEqual(command.proxy.registrationStateObservations.count, 1,
                   "Calling observeRegistrationState(_:) should store a handler.")
  }
  
  func testResetRegistration() {
    let command = KeyCommand(
      name: "Command4",
      key: .comma,
      modifiers: [.option])
    XCTAssertFalse(command.proxy.isRegistered)
    command.proxy.register()
    XCTAssertTrue(command.proxy.isRegistered)
    command.proxy.unregister(shouldReregister: true)
    XCTAssertTrue(command.proxy.isRegistered)
    command.proxy.unregister(shouldReregister: false)
    XCTAssertFalse(command.proxy.isRegistered)
  }
}
