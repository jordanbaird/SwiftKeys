//===----------------------------------------------------------------------===//
//
// BorderViewTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class BorderViewTests: TestCase {
  private let recorder = KeyRecorder(name: "SomeCommand")
  private let borderView = MockBorderView()
  
  func testCornerRadius() {
    XCTAssertEqual(borderView.cornerRadius, 5.5)
    borderView.cornerRadius = 10
    XCTAssertEqual(borderView.cornerRadius, 10)
  }
  
  func testBorderStyle() {
    XCTAssertEqual(borderView.borderStyle, .solid)
    borderView.borderStyle = .dashed
    XCTAssertEqual(borderView.borderStyle, .dashed)
  }
  
  func testBorderColor() {
    XCTAssertEqual(borderView.borderColor, .highlightColor)
    borderView.borderColor = .orange
    XCTAssertEqual(borderView.borderColor, .orange)
  }
  
  func testBorderThickness() {
    XCTAssertEqual(borderView.borderThickness, 1)
    borderView.borderThickness = 10
    XCTAssertEqual(borderView.borderThickness, 10)
  }
  
  func testDraw() {
    borderView.draw(borderView.bounds)
    wait(for: [borderView.didDrawExpectation], timeout: 1)
  }
}

private class MockBorderView: KeyRecorder.BorderView {
  let didDrawExpectation = XCTestExpectation(description: "Draw method was called.")
  
  init() {
    super.init(
      frame: .zero,
      borderColor: .highlightColor,
      borderStyle: .solid,
      borderThickness: 1,
      cornerRadius: 5.5)
  }
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    didDrawExpectation.fulfill()
  }
}
