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
  
  func testHighlight() {
    for style in KeyRecorder.HighlightStyle.allCases {
      recorder.isHighlighted = false
      XCTAssert(!recorder.subviews.contains(recorder.highlightView))
      
      recorder.highlightStyle = style
      recorder.isHighlighted = true
      XCTAssert(recorder.subviews.contains(recorder.highlightView))
      
      XCTAssertEqual(recorder.highlightView.layer?.backgroundColor, style.highlightColor.cgColor)
      XCTAssertEqual(recorder.highlightView.material, style.material)
    }
  }
  
  func testAppearance() {
    let allAppearances: [NSAppearance] = [
      .init(named: .aqua)!,
      .init(named: .darkAqua)!,
      .init(named: .vibrantLight)!,
      .init(named: .vibrantDark)!,
    ]
    
    XCTAssertEqual(recorder.appearance, recorder.segmentedControl.appearance)
    
    for appearance in allAppearances {
      recorder.appearance = appearance
      XCTAssertEqual(recorder.appearance, recorder.segmentedControl.appearance)
      XCTAssertEqual(recorder.segmentedControl.appearance, appearance)
    }
  }
  
  func testBezelStyle() {
    XCTAssert(recorder.bezelStyle == .rounded)
    recorder.bezelStyle = .flatBordered
    XCTAssert(recorder.bezelStyle == .flatBordered)
    XCTAssert(recorder.segmentedControl.segmentStyle == .roundRect)
  }
  
  func testStringValue() {
    let label = KeyRecorder.SegmentedControl.Label.recordShortcut
    let newStringValue = "New String Value"
    XCTAssert(recorder.stringValue == label.rawValue)
    recorder.stringValue = newStringValue
    XCTAssert(recorder.stringValue == newStringValue)
    XCTAssert(recorder.segmentedControl.label(forSegment: 0) == newStringValue)
  }
  
  func testAlignment() {
    XCTAssert(recorder.alignment == .center)
    XCTAssert(recorder.segmentedControl.alignment(forSegment: 0) == .center)
    recorder.alignment = .left
    XCTAssert(recorder.alignment == .left)
    XCTAssert(recorder.segmentedControl.alignment(forSegment: 0) == .left)
  }
}
