//===----------------------------------------------------------------------===//
//
// Modifier.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox
import CoreGraphics
import AppKit

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
      case .command: return "⌘"
      case .control: return "⌃"
      case .option: return "⌥"
      case .shift: return "⇧"
      }
    }
    
    var cgEventFlag: CGEventFlags {
      switch self {
      case .command: return .maskCommand
      case .control: return .maskControl
      case .option: return .maskAlternate
      case .shift: return .maskShift
      }
    }
    
    var cocoaFlag: NSEvent.ModifierFlags {
      switch self {
      case .command: return .command
      case .control: return .control
      case .option: return .option
      case .shift: return .shift
      }
    }
    
    var carbonFlag: Int {
      switch self {
      case .command: return cmdKey
      case .control: return controlKey
      case .option: return optionKey
      case .shift: return shiftKey
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
          || contains(where: { $0.cgEventFlag.contains(modifier.cgEventFlag) })
      {
        converted |= modifier.carbonFlag
      }
    }
    return .init(converted)
  }
  
  var cocoaFlags: NSEvent.ModifierFlags {
    var flags = NSEvent.ModifierFlags()
    for modifier in self {
      flags.insert(modifier.cocoaFlag)
    }
    return flags
  }
}
