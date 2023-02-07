//===----------------------------------------------------------------------===//
//
// Modifier.swift
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox
import Cocoa

// MARK: - KeyCommand Modifier

extension KeyCommand {
    /// Constants that represent the modifier keys of a key command.
    public enum Modifier {
        /// The Control key.
        case control
        /// The Option, or Alt key.
        case option
        /// The Shift key.
        case shift
        /// The Command key.
        case command
    }
}

// MARK: Modifier Properties
extension KeyCommand.Modifier {
    /// The modifier key's string representation.
    public var stringValue: String {
        switch self {
        case .control:
            return "⌃"
        case .option:
            return "⌥"
        case .shift:
            return "⇧"
        case .command:
            return "⌘"
        }
    }

    /// The `CGEventFlags` value associated with the modifier key.
    var cgEventFlag: CGEventFlags {
        switch self {
        case .control:
            return .maskControl
        case .option:
            return .maskAlternate
        case .shift:
            return .maskShift
        case .command:
            return .maskCommand
        }
    }

    /// The `NSEvent.ModifierFlags` value associated with the modifier key.
    var cocoaFlag: NSEvent.ModifierFlags {
        switch self {
        case .control:
            return .control
        case .option:
            return .option
        case .shift:
            return .shift
        case .command:
            return .command
        }
    }

    /// An integer value associated with the modifier key, as defined by
    /// the `Carbon` framework.
    var carbonFlag: Int {
        switch self {
        case .control:
            return controlKey
        case .option:
            return optionKey
        case .shift:
            return shiftKey
        case .command:
            return cmdKey
        }
    }
}

// MARK: Modifier Methods
extension KeyCommand.Modifier {
    /// An unsigned version of the modifier key's `carbonFlag`.
    func unsigned<U: UnsignedInteger>(type: U.Type = U.self) -> U {
        U(carbonFlag)
    }
}

// MARK: Modifier: CaseIterable
extension KeyCommand.Modifier: CaseIterable { }

// MARK: Modifier: Codable
extension KeyCommand.Modifier: Codable { }

// MARK: Modifier: Equatable
extension KeyCommand.Modifier: Equatable { }

// MARK: Modifier: Hashable
extension KeyCommand.Modifier: Hashable { }

// MARK: - [Modifier]

extension [KeyCommand.Modifier] {
    /// The order that macOS represents its modifier keys, according
    /// to the Apple Style Guide.
    static let canonicalOrder: Self = {
        let canonicalOrder: Self = [
            .control,
            .option,
            .shift,
            .command,
        ]
        assert(
            canonicalOrder.count == KeyCommand.Modifier.allCases.count,
            "Canonical order of \(Self.self) does not contain all cases."
        )
        return canonicalOrder
    }()

    /// The combined string value of the modifier keys.
    var stringValue: String {
        map { $0.stringValue }.joined()
    }

    /// The flags for the modifier keys, as defined by the `Carbon`
    /// framework, or'd together into a single integer.
    var carbonFlags: Int {
        var converted = 0
        for modifier in Self.canonicalOrder where contains(modifier) {
            converted |= modifier.carbonFlag
        }
        return converted
    }

    /// The `NSEvent.ModifierFlags` value for the modifier keys,
    /// reduced into a single value.
    var cocoaFlags: NSEvent.ModifierFlags {
        reduce(into: []) { $0.insert($1.cocoaFlag) }
    }

    /// Creates an array of modifier keys based on the given `Carbon`
    /// value.
    init(carbonModifiers: Int) {
        self = Self.canonicalOrder.filter(carbonModifiers.bitwiseContains)
    }

    /// An unsigned version of the modifier keys' `carbonFlags`.
    func unsigned<U: UnsignedInteger>(type: U.Type = U.self) -> U {
        U(carbonFlags)
    }
}

// MARK: - BinaryInteger

extension BinaryInteger {
    /// Returns a Boolean value indicating whether the bits of this
    /// integer contain the bits of another integer.
    func bitwiseContains<Other: BinaryInteger>(_ other: Other) -> Bool {
        let other = Self(other)
        return other & self == other
    }

    /// Returns a Boolean value indicating whether the bits of this
    /// integer contain the bits of the given modifier key's `carbonFlag`.
    func bitwiseContains(modifier: KeyCommand.Modifier) -> Bool {
        bitwiseContains(modifier.carbonFlag)
    }
}
