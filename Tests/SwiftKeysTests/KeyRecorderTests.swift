//===----------------------------------------------------------------------===//
//
// KeyRecorderTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class KeyRecorderTests: XCTestCase {
  var recorder: KeyRecorder!
  let window = NSWindow()
  
  override func setUp() {
    KeyEvent(name: "SomeKeyEvent").remove()
    recorder = .init(name: "SomeKeyEvent")
    recorder.removeFromSuperview()
    window.contentView?.addSubview(recorder)
    recorder.isEnabled = true
    recorder.hasBackingView = true
  }
  
  func testRecorder() {
    XCTAssert(recorder.isEnabled)
    recorder.isEnabled = false
    XCTAssert(!recorder.isEnabled)
    XCTAssert(recorder.hasBackingView)
    recorder.hasBackingView = false
    XCTAssert(!recorder.hasBackingView)
  }
  
  func testSimulatePress() {
    XCTAssert(recorder.segmentedControl.recordingState == .idle)
    recorder.segmentedControl.setSelected(true, forSegment: 0)
    recorder.segmentedControl.controlWasPressed(recorder.segmentedControl)
    XCTAssert(recorder.segmentedControl.recordingState == .recording)
    recorder.segmentedControl.setSelected(true, forSegment: 1)
    recorder.segmentedControl.controlWasPressed(recorder.segmentedControl)
    XCTAssert(recorder.segmentedControl.recordingState == .idle)
  }
  
  func testRecord() {
    let event = KeyEvent(name: "SomeKeyEvent")
    XCTAssertNil(event.key)
    XCTAssert(event.modifiers.isEmpty)
    recorder.segmentedControl.record(key: .return, modifiers: [.command, .control])
    XCTAssert(event.key == .return)
    XCTAssert(event.modifiers == [.command, .control])
  }
}
