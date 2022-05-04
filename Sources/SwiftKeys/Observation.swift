//===----------------------------------------------------------------------===//
//
// Observation.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox

protocol IdentifiableObservation: IdentifiableWrapper where Value == () -> Void { }

extension IdentifiableObservation {
  func perform() { value() }
}

struct AnyIdentifiableObservation: IdentifiableObservation {
  let base: Any
  let id: Identifier
  let value: () -> Void
  
  init<T: IdentifiableObservation>(_ base: T) {
    self.base = base
    id = base.id
    value = base.value
  }
}

extension KeyEvent {
  /// The result type of a call to ``KeyEvent/observe(_:handler:)``.
  ///
  /// You can pass an instance of this type into its key event's
  /// ``KeyEvent/removeObservation(_:)`` method, or similar, to permanently
  /// remove the observation and stop the execution of its handler.
  public struct Observation: IdentifiableObservation {
    let id = idGenerator.next()
    let eventType: KeyEvent.EventType
    let value: () -> Void
    
    func tryToPerform(with eventRef: EventRef) {
      if KeyEvent.EventType(eventRef) == eventType {
        value()
      }
    }
  }
}

extension KeyEvent.Observation: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

extension KeyEvent.Observation: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
