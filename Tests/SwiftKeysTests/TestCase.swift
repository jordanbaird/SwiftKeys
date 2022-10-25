//===----------------------------------------------------------------------===//
//
// TestCase.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

class TestCase: XCTestCase {
  override func tearDownWithError() throws {
    try Proxy.uninstall()
  }
}
