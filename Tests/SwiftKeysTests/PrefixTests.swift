//===----------------------------------------------------------------------===//
//
// PrefixTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class PrefixTests: TestCase {
  override func setUp() {
    super.setUp()
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
    let n1 = KeyCommand.Name("Name1")
    XCTAssertEqual(n1.prefix.rawValue, "Prefix1")
    
    prefix = "Prefix2"
    let n2 = KeyCommand.Name("Name2")
    XCTAssertEqual(n2.prefix.rawValue, "Prefix2")
  }
  
  func testHashValue() {
    let p1 = KeyCommand.Name.Prefix("Hello")
    let p2: KeyCommand.Name.Prefix = "Hello"
    let p3 = KeyCommand.Name.Prefix("Goodbye")
    
    XCTAssertEqual(p1.hashValue, p2.hashValue,
              "Identical prefixes should have identical hash values.")
    XCTAssertNotEqual(p2.hashValue, p3.hashValue,
              "Different prefixes should have different hash values.")
  }
}

var prefix = ""
extension KeyCommand.Name.Prefix {
  public override var sharedPrefix: Self { .init(prefix) }
}
