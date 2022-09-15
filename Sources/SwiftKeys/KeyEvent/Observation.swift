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
    /// The identifying value of this observation.
    public let id = rng.next()
    
    /// The type of the event that this observation reacts to.
    public let eventType: EventType
    
    let value: () -> Void
    
    /// An action that is performed when this observation is triggered.
    public var handler: () -> Void { value }
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

extension [KeyEvent.Observation] {
  func tryToPerformEach(_ eventType: KeyEvent.EventType?) {
    for observation in self where observation.eventType == eventType {
      observation.handler()
    }
  }
}
