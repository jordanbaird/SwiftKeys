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
    UserDefaults.standard.set("Value", forKey: "Key")
    let name = kCFPreferencesCurrentApplication as String
    XCTAssertNotNil(UserDefaults.standard.persistentDomain(forName: name))
    for def in UserDefaults.standard.persistentDomain(forName: name) ?? [:] {
      UserDefaults.standard.removeObject(forKey: def.key)
    }
    XCTAssertNil(UserDefaults.standard.persistentDomain(forName: name))
  }
  
  func testPrefix() {
    prefix = "Prefix1"
    let n1 = KeyEvent.Name("Name1")
    XCTAssertEqual(n1.prefix.rawValue, "Prefix1")
    
    prefix = "Prefix2"
    let n2 = KeyEvent.Name("Name2")
    XCTAssertEqual(n2.prefix.rawValue, "Prefix2")
  }
  
  func testStringLiteralPrefix() {
    let p1 = KeyEvent.Name.Prefix("Prefix")
    let p2: KeyEvent.Name.Prefix = "Prefix"
    XCTAssertEqual(p1, p2, "String literals should function as valid prefixes.")
  }
  
  func testUnderlyingReference() {
    let e1 = KeyEvent(name: "Name", key: .return, modifiers: .command, .shift, .option)
    let e2 = KeyEvent(name: "Name")
    XCTAssertEqual(e1, e2, "Events with the same name should be equal.")
    XCTAssertEqual(e2.key, .return)
    XCTAssertEqual(e2.modifiers, [.command, .shift, .option])
  }
  
  func testHashValue() {
    let p1 = KeyEvent.Name.Prefix("Hello")
    let p2: KeyEvent.Name.Prefix = "Hello"
    let p3 = KeyEvent.Name.Prefix("Goodbye")
    
    XCTAssert(p1.hashValue == p2.hashValue,
              "Identical prefixes should have identical hash values.")
    XCTAssert(p2.hashValue != p3.hashValue,
              "Different prefixes should have different hash values.")
  }
}

var prefix = ""
extension KeyEvent.Name.Prefix {
  public override var sharedPrefix: Self { .init(prefix) }
}
