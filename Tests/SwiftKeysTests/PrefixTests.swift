//===----------------------------------------------------------------------===//
//
// PrefixTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class PrefixTests: XCTestCase {
  override func setUp() {
    // Ensures that the defaults domain is wiped before every test.
    do {
      UserDefaults.standard.set("Test", forKey: "Test")
      let name = kCFPreferencesCurrentApplication as String
      XCTAssert(UserDefaults.standard.persistentDomain(forName: name) != nil)
      for def in UserDefaults.standard.persistentDomain(forName: name) ?? [:] {
        UserDefaults.standard.removeObject(forKey: def.key)
      }
      XCTAssert(UserDefaults.standard.persistentDomain(forName: name) == nil)
    }
  }
  
  func testPrefix() throws {
    prefix = "Prefix1"
    let name1 = KeyEvent.Name("Name1")
    
    XCTAssert(name1.prefix.rawValue == "Prefix1")
    
    prefix = "Prefix2"
    let name2 = KeyEvent.Name("Name2")
    
    XCTAssert(name2.prefix.rawValue == "Prefix2")
    XCTAssert(name1.prefix.rawValue == "Prefix1")
    
    let event1 = KeyEvent(name: name1, key: .return, modifiers: .command, .shift, .option)
    let event2 = KeyEvent(name: name1)
    
    XCTAssertEqual(event1, event2)
    
    XCTAssert(event2.key == .return)
    XCTAssert(event2.modifiers == [.command, .shift, .option])
    
    let stringLiteralPrefix: KeyEvent.Name.Prefix = "Prefix2"
    XCTAssertEqual(stringLiteralPrefix.sharedPrefix, stringLiteralPrefix)
  }
  
  func testEqual() {
    let prefix1 = KeyEvent.Name.Prefix("Hello")
    let prefix2: KeyEvent.Name.Prefix = "Hello"
    XCTAssertEqual(prefix1, prefix2)
  }
  
  func testNotEqual() {
    let prefix1 = KeyEvent.Name.Prefix("Hello")
    let prefix2 = KeyEvent.Name.Prefix("Goodbye")
    XCTAssertNotEqual(prefix1, prefix2)
  }
  
  func testHashValue() {
    let prefix1 = KeyEvent.Name.Prefix("Hello")
    let prefix2: KeyEvent.Name.Prefix = "Hello"
    let prefix3 = KeyEvent.Name.Prefix("Goodbye")
    XCTAssertEqual(prefix1.hashValue, prefix2.hashValue)
    XCTAssertNotEqual(prefix2.hashValue, prefix3.hashValue)
  }
}

var prefix = ""
extension KeyEvent.Name.Prefix {
  public override var sharedPrefix: Self { .init(prefix) }
}
