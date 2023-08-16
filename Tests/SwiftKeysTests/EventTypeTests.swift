//
//  EventTypeTests.swift
//  SwiftKeys
//

import Carbon.HIToolbox
import XCTest
@testable import SwiftKeys

final class EventTypeTests: SKTestCase {
    typealias EventType = KeyCommand.EventType

    func testInitWithCarbonConstant() {
        XCTAssertEqual(EventType(kEventHotKeyPressed), .keyDown)
        XCTAssertEqual(EventType(kEventRawKeyDown), .keyDown)

        XCTAssertEqual(EventType(kEventHotKeyReleased), .keyUp)
        XCTAssertEqual(EventType(kEventRawKeyUp), .keyUp)

        // Any other value should initialize to nil.
        XCTAssertNil(EventType(kEventHotKeyNoOptions))
    }

    func testInitWithValidEventRef() throws {
        //
        // Create two CGEvents that we know will be keyDown and keyUp,
        // respectively. Try to create EventType instances from each of
        // them. For this test to succeed, the created EventType should
        // match for both keyDown and keyUp.
        //

        let keyDownEvent = try XCTUnwrap(
            CGEvent(
                keyboardEventSource: CGEventSource(stateID: .hidSystemState),
                virtualKey: 6,
                keyDown: true
            )
        )
        let keyUpEvent = try XCTUnwrap(
            CGEvent(
                keyboardEventSource: CGEventSource(stateID: .hidSystemState),
                virtualKey: 6,
                keyDown: false
            )
        )

        var keyDownRef: EventRef?
        var keyUpRef: EventRef?

        XCTAssert(
            CreateEventWithCGEvent(nil, keyDownEvent, UInt32(kEventAttributeNone), &keyDownRef) == noErr,
            "Returned status code should be noErr."
        )
        XCTAssert(
            CreateEventWithCGEvent(nil, keyUpEvent, UInt32(kEventAttributeNone), &keyUpRef) == noErr,
            "Returned status code should be noErr."
        )

        try XCTAssertEqual(EventType(XCTUnwrap(keyDownRef)), .keyDown)
        try XCTAssertEqual(EventType(XCTUnwrap(keyUpRef)), .keyUp)
    }

    func testInitWithInvalidEventRef() throws {
        //
        // Create a CGEvent that we know won't be keyUp or keyDown.
        // Try to create an instance of EventType from it. For this
        // test to succeed, the EventType creation should fail.
        //

        let event = try XCTUnwrap(CGEvent(source: nil))

        var eventRef: EventRef?

        XCTAssert(
            CreateEventWithCGEvent(nil, event, UInt32(kEventAttributeNone), &eventRef) == noErr,
            "Returned status code should be noErr."
        )

        let eventType = try EventType(XCTUnwrap(eventRef))
        XCTAssertNil(eventType)
    }
}
