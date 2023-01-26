//===----------------------------------------------------------------------===//
//
// KeyCommandTests.swift
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import SwiftKeys

final class KeyCommandTests: TestCase {
    typealias EventType = KeyCommand.EventType

    typealias Observation = KeyCommand.Observation

    typealias Modifier = KeyCommand.Modifier

    func testProxySharing() {
        //
        // Two key commands with the same name should
        // share the same proxy.
        //

        let command1 = KeyCommand(name: "TestCommand0")
        let command2 = KeyCommand(name: "TestCommand0")
        XCTAssertEqual(command1.proxy, command2.proxy)
    }

    func testValueSharing() {
        //
        // If a command is created with the same name as an
        // existing command, and has different keys and/or modifiers,
        // both commands should assume the value of the newest one.
        //

        let command1 = KeyCommand(
            name: "TestCommand1",
            key: .b,
            modifiers: [.command])

        XCTAssertEqual(KeyCommand(name: "TestCommand1").key, .b)
        XCTAssertEqual(KeyCommand(name: "TestCommand1").modifiers, [.command])

        let command2 = KeyCommand(
            name: "TestCommand1",
            key: .l,
            modifiers: [.option])

        XCTAssertEqual(command1, command2)
        XCTAssertEqual(KeyCommand(name: "TestCommand1").key, .l)
        XCTAssertEqual(KeyCommand(name: "TestCommand1").modifiers, [.option])
    }

    func testEnable() {
        let command = KeyCommand(
            name: "TestCommand2",
            key: .a,
            modifiers: .option, .shift)

        XCTAssertFalse(
            command.isEnabled,
            "A key command that has just been created should not be enabled.")

        command.observe(.keyDown) { }
        XCTAssert(
            command.isEnabled,
            "Observing a key command should enable it.")

        command.disable()
        XCTAssertFalse(
            command.isEnabled,
            "Calling `disable()` on a key command should disable it.")

        XCTAssertNotNil(
            command.key,
            "Nothing has changed with the command. Its key should not be nil.")
        XCTAssertFalse(
            command.modifiers.isEmpty,
            "Nothing has changed with the command. Its modifiers should not be empty.")

        command.remove()

        XCTAssertNil(
            command.key,
            "Calling `remove()` on a key command should set its key to nil.")
        XCTAssert(
            command.modifiers.isEmpty,
            "Calling `remove()` on a key command should remove all of its modifiers.")
    }

    func testObservation() {
        var lastRunEventType: EventType?

        @Builder<Observation> var observations: [Observation] {
            Observation(.keyDown) {
                lastRunEventType = .keyDown
            }
            Observation(.keyUp) {
                lastRunEventType = .keyUp
            }
            Observation(.doubleTap(1)) {
                lastRunEventType = .doubleTap(1)
            }
            Observation(.doubleTap(0.1)) {
                lastRunEventType = nil
            }
        }

        XCTAssertNil(lastRunEventType)

        observations.performObservations(matching: .keyDown)
        XCTAssertEqual(lastRunEventType, .keyDown)
        observations.performObservations(matching: .keyUp)
        XCTAssertEqual(lastRunEventType, .keyUp)
        observations.performObservations(matching: .doubleTap(1))
        XCTAssertEqual(lastRunEventType, .doubleTap(1))
        observations.performObservations(matching: .doubleTap(0.1))
        XCTAssertNil(lastRunEventType)
        observations.performObservations(where: { $0 == .keyUp })
        XCTAssertEqual(lastRunEventType, .keyUp)
    }

    func testRemoveSpecificObservations() {
        var lastRunEventType: EventType?
        let command = KeyCommand(name: "TestCommand3")

        let keyDownObservation = command.observe(.keyDown) {
            lastRunEventType = .keyDown
        }

        let keyUpObservation = command.observe(.keyUp) {
            lastRunEventType = .keyUp
        }

        XCTAssertNil(lastRunEventType)

        command.runHandlers(for: .keyDown)
        XCTAssertEqual(lastRunEventType, .keyDown)
        command.runHandlers(for: .keyUp)
        XCTAssertEqual(lastRunEventType, .keyUp)

        lastRunEventType = nil
        command.removeObservation(keyUpObservation)
        command.runHandlers(for: .keyDown)
        command.runHandlers(for: .keyUp)

        XCTAssertEqual(lastRunEventType, .keyDown)

        lastRunEventType = nil
        command.removeObservation(keyDownObservation)
        command.runHandlers(for: .keyDown)

        XCTAssertNil(lastRunEventType)
    }

    func testRemoveNonSpecificObservations() {
        var lastRunEventType: EventType?
        let command = KeyCommand(name: "TestCommand4")

        command.observe(.keyDown) {
            lastRunEventType = .keyDown
        }

        command.observe(.keyUp) {
            lastRunEventType = .keyUp
        }

        XCTAssertNil(lastRunEventType)

        command.runHandlers { $0.eventType == .keyDown }
        XCTAssertEqual(lastRunEventType, .keyDown)

        command.runHandlers { $0.eventType == .keyUp }
        XCTAssertEqual(lastRunEventType, .keyUp)

        lastRunEventType = nil

        command.removeObservations { $0.eventType == .keyUp }

        command.runHandlers(for: .keyUp)
        XCTAssertNil(lastRunEventType)

        command.runHandlers(for: .keyDown)
        XCTAssertEqual(lastRunEventType, .keyDown)
    }

    func testRemoveFirstObservation() {
        enum RunInfo {
            case firstKeyDown
            case secondKeyDown
            case firstKeyUp
        }

        var runInfo = [RunInfo]()
        let command = KeyCommand(name: "TestCommand5")

        command.observe(.keyDown) {
            runInfo.append(.firstKeyDown)
        }

        command.observe(.keyDown) {
            runInfo.append(.secondKeyDown)
        }

        command.observe(.keyUp) {
            runInfo.append(.firstKeyUp)
        }

        XCTAssertTrue(runInfo.isEmpty)

        command.runHandlers(for: .keyDown)
        XCTAssertEqual(runInfo.count, 2)
        XCTAssertEqual(runInfo[0], .firstKeyDown)
        XCTAssertEqual(runInfo[1], .secondKeyDown)

        command.runHandlers(for: .keyUp)
        XCTAssertEqual(runInfo.count, 3)
        XCTAssertEqual(runInfo[2], .firstKeyUp)

        runInfo.removeAll()

        command.removeFirstObservation { $0.eventType == .keyDown }

        command.runHandlers(for: .keyDown)
        XCTAssertEqual(runInfo.count, 1)
        XCTAssertEqual(runInfo[0], .secondKeyDown)
    }

    func testRemoveAllObservations() {
        var lastRunEventType: EventType?
        let command = KeyCommand(name: "TestCommand6")

        command.observe(.keyDown) {
            lastRunEventType = .keyDown
        }

        command.observe(.keyUp) {
            lastRunEventType = .keyUp
        }

        XCTAssertNil(lastRunEventType)

        command.runHandlers(for: .keyDown)
        XCTAssertEqual(lastRunEventType, .keyDown)

        command.runHandlers(for: .keyUp)
        XCTAssertEqual(lastRunEventType, .keyUp)

        lastRunEventType = nil

        command.removeAllObservations()

        command.runHandlers(for: .keyDown)
        command.runHandlers(for: .keyUp)

        XCTAssertNil(lastRunEventType)
    }

    func testSystemReserved() {
        XCTAssertTrue(KeyCommand.isReservedBySystem(key: .escape, modifiers: [.command]))
        XCTAssertFalse(KeyCommand.isReservedBySystem(key: .space, modifiers: [.control]))
    }

    func testCarbonModifiers() {
        let modifiers: [Modifier] = [.control, .shift, .command]
        let carbonModifiers = modifiers.carbonFlags
        let recreatedModifiers = [Modifier](carbonModifiers: carbonModifiers)
        XCTAssert(modifiers.allSatisfy { recreatedModifiers.contains($0) })
    }

    func testModifiersToNSEventFlags() {
        let pairs: [(NSEvent.ModifierFlags, Modifier)] = [
            (.control, .control),
            (.option, .option),
            (.shift, .shift),
            (.command, .command),
        ]
        var nsEventFlags = NSEvent.ModifierFlags()
        var correctModifiers = [Modifier]()
        for pair in pairs {
            nsEventFlags.insert(pair.0)
            correctModifiers.append(pair.1)
            XCTAssertEqual(nsEventFlags.swiftKeysModifiers, correctModifiers)
        }
    }

    func testModifiersStringValue() {
        XCTAssertEqual([Modifier].canonicalOrder.stringValue, "⌃⌥⇧⌘")
    }
}
