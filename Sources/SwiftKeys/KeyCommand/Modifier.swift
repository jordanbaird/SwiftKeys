//===----------------------------------------------------------------------===//
//
// Modifier.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit
import Carbon.HIToolbox
import CoreGraphics

extension KeyCommand {
  /// Constants that represent modifier keys associated with a key command.
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
    
    /// The `CGEventFlags` value associated with the modifier.
    var cgEventFlag: CGEventFlags {
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
    
    /// The `NSEvent.ModifierFlags` value associated with the modifier.
    var cocoaFlag: NSEvent.ModifierFlags {
      switch self {
      case .command:
        return .command
      case .control:
        return .control
      case .option:
        return .option
      case .shift:
        return .shift
      }
    }
    
    /// An integer value associated with the modifier, as defined by
    /// the `Carbon` framework.
    var carbonFlag: Int {
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

extension KeyCommand.Modifier: Codable { }

extension KeyCommand.Modifier: Equatable { }

extension KeyCommand.Modifier: Hashable { }

extension Array where Element == KeyCommand.Modifier {
  init?(carbonModifiers: Int) {
    self.init()
    for modifier in KeyCommand.Modifier.allCases
      where carbonModifiers.containsModifier(modifier)
    {
      append(modifier)
    }
    if isEmpty {
      return nil
    }
  }
  
  /// Returns a Boolean value indicating whether the array contains the
  /// given modifier, evaluated fuzzily.
  ///
  /// If the array does not directly contain the given modifier, another
  /// check is run to determine if the array instead contains a modifier
  /// whose associated `cgEventFlag` value matches that of the modifier.
  func fuzzyContains(_ modifier: KeyCommand.Modifier) -> Bool {
    contains(modifier)
    ||
    contains {
      $0.cgEventFlag.contains(modifier.cgEventFlag)
    }
  }
}

extension Array where Element == KeyCommand.Modifier {
  /// The flags for the given modifiers, as defined by the `Carbon` framework,
  /// or'd together into a single unsigned integer.
  var carbonFlags: UInt32 {
    var converted = 0
    for modifier in KeyCommand.Modifier.allCases where fuzzyContains(modifier) {
      converted |= modifier.carbonFlag
    }
    return .init(converted)
  }
  
  /// The `NSEvent.ModifierFlags` value for the given modifiers, reduced
  /// into a single value.
  var cocoaFlags: NSEvent.ModifierFlags {
    reduce(into: .init()) {
      $0.insert($1.cocoaFlag)
    }
  }
}

extension Int {
  func bitwiseContains(_ other: Int) -> Bool {
    other & self == other
  }
  
  func containsModifier(_ modifier: KeyCommand.Modifier) -> Bool {
    bitwiseContains(modifier.carbonFlag)
  }
}
