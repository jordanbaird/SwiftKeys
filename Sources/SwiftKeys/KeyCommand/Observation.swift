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

extension KeyCommand {
  /// The result type of a call to ``KeyCommand/observe(_:handler:)``.
  ///
  /// You can pass an instance of this type into the ``KeyCommand/removeObservation(_:)``
  /// method, or similar, to permanently remove the observation and stop the execution of
  /// its handler.
  public struct Observation: IdentifiableObservation {
    /// The identifying value of the observation.
    public let id = rng.next()
    
    /// The event type of the observation.
    public let eventType: EventType
    
    let value: () -> Void
    
    /// An action that is performed when the observation is triggered.
    public var handler: () -> Void { value }
  }
}

extension KeyCommand.Observation: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

extension KeyCommand.Observation: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension Array where Element == KeyCommand.Observation {
  func performObservations(matching eventType: KeyCommand.EventType?) {
    for observation in self where observation.eventType == eventType {
      observation.handler()
    }
  }
}
