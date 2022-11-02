//===----------------------------------------------------------------------===//
//
// Identifiables.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

var rng = SystemRandomNumberGenerator()

protocol IdentifiableWrapper: Hashable {
  associatedtype Value
  associatedtype Identifier: Hashable
  var id: Identifier { get }
  var value: Value { get }
}

extension IdentifiableWrapper {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

extension IdentifiableWrapper {
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

protocol IdentifiableObservation: IdentifiableWrapper where Value == () -> Void { }

extension IdentifiableObservation {
  var perform: () -> Void { value }
}

struct AnyIdentifiableObservation: IdentifiableObservation {
  let base: Any
  let id: AnyHashable
  let value: () -> Void
  
  init<T: IdentifiableObservation>(_ base: T) {
    self.base = base
    id = base.id
    value = base.value
  }
}
