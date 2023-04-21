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
