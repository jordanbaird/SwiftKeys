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
    /// The Control key.
    case control
    /// The Option, or Alt key.
    case option
    /// The Shift key.
    case shift
    /// The Command key.
    case command
    
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

extension KeyCommand.Modifier: Codable { }

extension KeyCommand.Modifier: Equatable { }

extension KeyCommand.Modifier: Hashable { }

extension Array where Element == KeyCommand.Modifier {
  /// The order that macOS represents its hotkeys, according to the
  /// [Apple Style Guide](https://support.apple.com/guide/applestyleguide/k-apsgf9067ae8/1.0/web/1.0)
  static let canonicalOrder = [
    KeyCommand.Modifier.control,
    KeyCommand.Modifier.option,
    KeyCommand.Modifier.shift,
    KeyCommand.Modifier.command,
  ]
  
  var stringValue: String {
    reduce("") { $0 + $1.stringValue }
  }
  
  /// The flags for the given modifiers, as defined by the `Carbon`
  /// framework, or'd together into a single unsigned integer.
  var carbonFlags: UInt32 {
    var converted: UInt32 = 0
    for modifier in KeyCommand.Modifier.allCases where fuzzyContains(modifier) {
      converted |= modifier.carbonFlag
    }
    return .init(converted)
  }
  
  /// The `NSEvent.ModifierFlags` value for the given modifiers,
  /// reduced into a single value.
  var cocoaFlags: NSEvent.ModifierFlags {
    reduce(into: .init()) {
      $0.insert($1.cocoaFlag)
    }
  }
  
  /// Creates an array of modifiers based on the given `Carbon` value.
  init?(carbonModifiers: UInt32) {
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
