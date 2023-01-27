//===----------------------------------------------------------------------===//
//
// KeyRecorderTests.swift
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class KeyRecorderTests: SKTestCase {
    var recorder: KeyRecorder!
    let window = NSWindow()

    override func setUp() {
        super.setUp()
        KeyCommand(name: "SomeKeyCommand").remove()
        recorder = .init(name: "SomeKeyCommand")
        recorder.removeFromSuperview()
        window.contentView?.addSubview(recorder)
        recorder.isEnabled = true
    }

    func testSimulatePress() {
        XCTAssertEqual(recorder.segmentedControl.recordingState, .idle)
        recorder.segmentedControl.setSelected(true, forSegment: 0)
        recorder.segmentedControl.controlWasPressed(recorder.segmentedControl)
        XCTAssertEqual(recorder.segmentedControl.recordingState, .recording)
        recorder.segmentedControl.setSelected(true, forSegment: 1)
        recorder.segmentedControl.controlWasPressed(recorder.segmentedControl)
        XCTAssertEqual(recorder.segmentedControl.recordingState, .idle)
    }

    func testRecord() {
        let command = KeyCommand(name: "SomeKeyCommand")
        XCTAssertNil(command.key)
        XCTAssert(command.modifiers.isEmpty)
        recorder.segmentedControl.record(key: .return, modifiers: [.command, .control])
        XCTAssertEqual(command.key, .return)
        XCTAssertEqual(command.modifiers, [.command, .control])
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

    func testStringValue() {
        let label = KeyRecorderSegmentedControl.Label.recordShortcut
        let newStringValue = "New String Value"
        XCTAssertEqual(recorder.stringValue, label.rawValue)
        recorder.stringValue = newStringValue
        XCTAssertEqual(recorder.stringValue, newStringValue)
        XCTAssertEqual(recorder.segmentedControl.label(forSegment: 0), newStringValue)
    }

    func testAlignment() {
        XCTAssertEqual(recorder.alignment, .center)
        XCTAssertEqual(recorder.segmentedControl.alignment(forSegment: 0), .center)
        recorder.alignment = .left
        XCTAssertEqual(recorder.alignment, .left)
        XCTAssertEqual(recorder.segmentedControl.alignment(forSegment: 0), .left)
    }
}
