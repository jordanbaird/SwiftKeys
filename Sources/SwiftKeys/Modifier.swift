//===----------------------------------------------------------------------===//
//
// Modifier.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox
import CoreGraphics

extension KeyEvent {
  /// Constants that represent modifier keys associated with a key event.
  public enum Modifier: CaseIterable {
    /// The Command key.
    case command
    /// The Control key.
    case control
    /// The Option, or Alt key.
    case option
    /// The Shift key.
    case shift
    
    /// A string representation of the modifier.
    public var stringValue: String {
      switch self {
      case .command:
        return "⌘"
      case .control:
        return "⌃"
      case .option:
        return "⌥"
      case .shift:
        return "⇧"
      }
    }
    
    var flag: CGEventFlags {
      switch self {
      case .command:
        return .maskCommand
      case .control:
        return .maskControl
      case .option:
        return .maskAlternate
      case .shift:
        return .maskShift
      }
    }
    
    var carbonValue: Int {
      switch self {
      case .command:
        return cmdKey
      case .control:
        return controlKey
      case .option:
        return optionKey
      case .shift:
        return shiftKey
      }
    }
  }
}

extension KeyEvent.Modifier: Codable { }

extension KeyEvent.Modifier: Equatable { }

extension KeyEvent.Modifier: Hashable { }

extension Array where Element == KeyEvent.Modifier {
  /// Gets the Carbon flags for the given modifiers, or'd together into
  /// a single unsigned integer.
  var carbonFlags: UInt32 {
    var converted = 0
    for modifier in KeyEvent.Modifier.allCases {
      if contains(modifier)
          || contains(where: { $0.flag.contains(modifier.flag) })
      {
        converted |= modifier.carbonValue
      }
    }
    return .init(converted)
  }
  
  /// Gets the `CGEventFlags` for the given modifiers joined together
  /// into a single instance.
  var cgEventFlags: CGEventFlags {
    var flags = CGEventFlags()
    for modifier in self {
      flags.insert(modifier.flag)
    }
    return flags
  }
}
