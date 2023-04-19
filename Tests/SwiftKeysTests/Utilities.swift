//
// Utilities.swift
// SwiftKeys
//

import XCTest
@testable import SwiftKeys

/// An `XCTestCase` class, customized for `SwiftKeys`.
class SKTestCase: XCTestCase {
    override func tearDownWithError() throws {
        try KeyCommandProxy.uninstall()
    }
}

extension SKTestCase {
    private func _unwrap<T>(
        _ block: () throws -> T?,
        _ message: () -> String,
        file: StaticString,
        line: UInt
    ) rethrows -> T {
        let value = try block()
        XCTAssertNotNil(value, message(), file: file, line: line)
        return value!
    }

    /// Asserts that the result of a block of code is not nil,
    /// and returns the unwrapped value.
    func unwrap<T>(
        _ block: () throws -> T?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) rethrows -> T {
        try _unwrap(block, message, file: file, line: line)
    }

    /// Asserts that an expression is not nil, and returns the
    /// unwrapped value.
    func unwrap<T>(
        _ expression: @autoclosure () throws -> T?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) rethrows -> T {
        try _unwrap(expression, message, file: file, line: line)
    }

    private func _assertAllEqual<T: Equatable>(
        _ itemBlock: () throws -> T,
        _ block: () throws -> [T],
        _ message: () -> String,
        file: StaticString,
        line: UInt
    ) rethrows {
        let targetItem = try itemBlock()
        let message = message()
        for item in try block() {
            XCTAssertEqual(item, targetItem, message, file: file, line: line)
        }
    }

    func assertAllEqual<T: Equatable>(
        to expression: @autoclosure () throws -> T,
        @Builder _ block: () throws -> [T],
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) rethrows {
        try _assertAllEqual(expression, block, message, file: file, line: line)
    }

    func assertAllEqual<T: Equatable>(
        to expression: @autoclosure () throws -> T,
        _ expressions: @autoclosure () throws -> [T],
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) rethrows {
        try _assertAllEqual(expression, expressions, message, file: file, line: line)
    }

    private func _assertAllSatisfyNoErr(
        _ block: () throws -> [OSStatus],
        _ message: () -> String,
        file: StaticString,
        line: UInt
    ) rethrows {
        let message = message()
        for status in try block() {
            XCTAssertEqual(status, noErr, message, file: file, line: line)
        }
    }

    /// Asserts that the result of a block of code is equal
    /// to `OSStatus.noErr`.
    func assertNoErr(
        @Builder _ block: () throws -> [OSStatus],
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) rethrows {
        try _assertAllSatisfyNoErr(block, message, file: file, line: line)
    }

    /// Asserts that the given status is equal to `OSStatus.noErr`.
    func assertNoErr(
        _ status: @autoclosure () throws -> OSStatus,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) rethrows {
        try _assertAllSatisfyNoErr({ [try status()] }, message, file: file, line: line)
    }
}

struct TestError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    init(_ status: OSStatus) {
        self.init("Received status with value: \(status)")
    }
}

@resultBuilder
struct Builder {
    static func buildBlock<T>(_ components: T...) -> [T] {
        components
    }
}
