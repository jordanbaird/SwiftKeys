//===----------------------------------------------------------------------===//
//
// Modifier.swift
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox
import Cocoa

extension KeyCommand {
    /// Constants that represent modifier keys associated with a key command.
    public enum Modifier {
        /// The Control key.
        case control
        /// The Option, or Alt key.
        case option
        /// The Shift key.
        case shift
        /// The Command key.
        case command

        // MARK: Properties

        /// A string representation of the modifier.
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

        /// The `CGEventFlags` value associated with the modifier.
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

        /// The `NSEvent.ModifierFlags` value associated with the modifier.
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

        /// An integer value associated with the modifier, as
        /// defined by the `Carbon` framework.
        var carbonFlag: UInt32 {
            switch self {
            case .control:
                return .init(controlKey)
            case .option:
                return .init(optionKey)
            case .shift:
                return .init(shiftKey)
            case .command:
                return .init(cmdKey)
            }
        }
    }
}

// MARK: - Protocol conformances

extension KeyCommand.Modifier: CaseIterable { }

extension KeyCommand.Modifier: Codable { }

extension KeyCommand.Modifier: Equatable { }

extension KeyCommand.Modifier: Hashable { }

// MARK: - Helpers

extension [KeyCommand.Modifier] {
    /// The order that macOS represents its hotkeys, according to
    /// the Apple Style Guide.
    static let canonicalOrder: Self = {
        let canonicalOrder: Self = [
            .control,
            .option,
            .shift,
            .command,
        ]
        assert(
            canonicalOrder.count == Element.allCases.count,
            "Canonical order of \(Element.self) does not contain all cases.")
        return canonicalOrder
    }()

    /// The combined string value of the modifiers.
    var stringValue: String {
        map { $0.stringValue }.joined()
    }

    /// The flags for the modifiers, as defined by the `Carbon` framework, or'd
    /// together into a single unsigned integer.
    var carbonFlags: UInt32 {
        var converted: UInt32 = 0
        for modifier in Self.canonicalOrder where contains(modifier) {
            converted |= modifier.carbonFlag
        }
        return converted
    }

    /// The `NSEvent.ModifierFlags` value for the modifiers, reduced into
    /// a single value.
    var cocoaFlags: NSEvent.ModifierFlags {
        reduce(into: .init()) {
            $0.insert($1.cocoaFlag)
        }
    }

    /// Creates an array of modifiers based on the given `Carbon` value.
    init(carbonModifiers modifiers: UInt32) {
        self = Self.canonicalOrder.filter {
            modifiers.containsModifier($0)
        }
    }
}

extension UInt32 {
    /// Returns a Boolean value indicating whether the bits
    /// of this integer contain the bits of another integer.
    func bitwiseContains(_ other: Self) -> Bool {
        other & self == other
    }

    /// Returns a Boolean value indicating whether the bits
    /// of this integer contain the bits of the given modifier's
    /// carbon flag value.
    func containsModifier(_ modifier: KeyCommand.Modifier) -> Bool {
        bitwiseContains(modifier.carbonFlag)
    }
}
