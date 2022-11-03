//===----------------------------------------------------------------------===//
//
// Observation.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox

extension KeyCommand {
  /// The result type of a call to ``KeyCommand/observe(_:handler:)``.
  ///
  /// You can pass an instance of this type into the ``KeyCommand/removeObservation(_:)``
  /// method, or similar, to permanently remove the observation and stop the execution of
  /// its handler.
  public struct Observation {
    private let base: IdentifiableObservation
    
    /// The event type of the observation.
    public let eventType: EventType
    
    init(eventType: EventType, handler: @escaping () -> Void) {
      self.eventType = eventType
      base = .init(handler: handler)
    }
    
    func perform() {
      base.perform()
    }
  }
}

extension KeyCommand.Observation: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.base == rhs.base
  }
}

extension KeyCommand.Observation: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(base)
  }
}

extension Array where Element == KeyCommand.Observation {
  func performObservations(matching eventType: KeyCommand.EventType?) {
    for observation in self where observation.eventType == eventType {
      observation.perform()
    }
  }
  
  func performObservations(where predicate: (KeyCommand.EventType) throws -> Bool) rethrows {
    for observation in self where try predicate(observation.eventType) {
      observation.perform()
    }
  }
}
