//===----------------------------------------------------------------------===//
//
// BorderViewTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class BorderViewTests: XCTestCase {
  private let recorder = KeyRecorder(name: "SomeEvent")
  private let borderView = MockBorderView()
  
  func testCornerRadius() {
    XCTAssert(borderView.cornerRadius == 5.5)
    borderView.cornerRadius = 10
    XCTAssert(borderView.cornerRadius == 10)
  }
  
  func testBorderStyle() {
    XCTAssert(borderView.borderStyle == .solid)
    borderView.borderStyle = .dashed
    XCTAssert(borderView.borderStyle == .dashed)
  }
  
  func testBorderColor() {
    XCTAssert(borderView.borderColor == .highlightColor)
    borderView.borderColor = .orange
    XCTAssert(borderView.borderColor == .orange)
  }
  
  func testBorderThickness() {
    XCTAssert(borderView.borderThickness == 1)
    borderView.borderThickness = 10
    XCTAssert(borderView.borderThickness == 10)
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
