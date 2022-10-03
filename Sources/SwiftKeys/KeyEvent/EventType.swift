//===----------------------------------------------------------------------===//
//
// EventType.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox

extension KeyEvent {
  /// Constants that specify the type of a key event.
  ///
  /// Pass these constants into a key event's ``observe(_:handler:)`` method.
  /// The closure you provide in that method will be called whenever an event
  /// of this type is posted.
  ///
  /// ```swift
  /// let event = KeyEvent(
  ///     name: "Cheese",
  ///     key: .leftArrow,
  ///     modifiers: [.command, .option]
  /// )
  ///
  /// event.observe(.keyDown) {
  ///     print("KEY DOWN")
  /// }
  ///
  /// event.observe(.keyUp) {
  ///     print("KEY UP")
  /// }
  /// ```
  ///
  /// - Tip: You can call ``observe(_:handler:)`` as many times as you want.
  public enum EventType {
    /// The key is released.
    case keyUp
    /// The key is pressed.
    case keyDown
    
    init?(_ eventKind: Int) {
      switch eventKind {
      case kEventHotKeyPressed:
        self = .keyDown
      case kEventHotKeyReleased:
        self = .keyUp
      default:
        return nil
      }
    }
    
    init?(_ eventRef: EventRef) {
      self.init(Int(GetEventKind(eventRef)))
    }
  }
}
