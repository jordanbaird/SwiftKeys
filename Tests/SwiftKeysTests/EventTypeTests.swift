//===----------------------------------------------------------------------===//
//
// EventTypeTests.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox
import XCTest
@testable import SwiftKeys

final class EventTypeTests: TestCase {
    typealias EventType = KeyCommand.EventType

    func testInitWithCarbonConstant() {
        // kEventHotKeyPressed and kEventRawKeyDown should both
        // initialize the keyDown EventType.
        assertAllEqual(to: .keyDown) {
            EventType(kEventHotKeyPressed)
            EventType(kEventRawKeyDown)
        }

        // kEventHotKeyReleased and kEventRawKeyUp should both
        // initialize the keyUp EventType.
        assertAllEqual(to: .keyUp) {
            EventType(kEventHotKeyReleased)
            EventType(kEventRawKeyUp)
        }

        // Any other value should initialize to nil.
        XCTAssertNil(EventType(kEventHotKeyNoOptions))
    }

    func testInitWithValidEventRef() throws {
        //
        // Create two CGEvents that we know will be keyDown and
        // keyUp, respectively. Try to create instances of EventType
        // from each of them. For this test to succeed, the created
        // EventType should match for both keyDown and keyUp.
        //

        let keyDownEvent = unwrap {
            CGEvent(
                keyboardEventSource: .init(stateID: .hidSystemState),
                virtualKey: 6,
                keyDown: true)
        }
        let keyUpEvent = unwrap {
            CGEvent(
                keyboardEventSource: .init(stateID: .hidSystemState),
                virtualKey: 6,
                keyDown: false)
        }

        var keyDownRef: EventRef?
        var keyUpRef: EventRef?

        assertNoErr {
            CreateEventWithCGEvent(
                nil,
                keyDownEvent,
                UInt32(kEventAttributeNone),
                &keyDownRef)
            CreateEventWithCGEvent(
                nil,
                keyUpEvent,
                UInt32(kEventAttributeNone),
                &keyUpRef)
        }

        XCTAssertEqual(EventType(unwrap(keyDownRef)), .keyDown)
        XCTAssertEqual(EventType(unwrap(keyUpRef)), .keyUp)
    }

    func testInitWithInvalidEventRef() throws {
        //
        // Create a CGEvent that we know won't be keyUp or keyDown.
        // Try to create an instance of EventType from it. For this
        // test to succeed, the EventType creation should fail.
        //

        let event = unwrap {
            CGEvent(
                scrollWheelEvent2Source: .init(stateID: .hidSystemState),
                units: .pixel,
                wheelCount: 1,
                wheel1: 0,
                wheel2: 0,
                wheel3: 0)
        }

        var eventRef: EventRef?

        assertNoErr {
            CreateEventWithCGEvent(
                nil,
                event,
                UInt32(kEventAttributeNone),
                &eventRef)
        }

        let eventType = EventType(unwrap(eventRef))
        XCTAssertNil(eventType)
    }
}
