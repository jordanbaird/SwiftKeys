//===----------------------------------------------------------------------===//
//
// IdentifiableObservation.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Foundation

struct IdentifiableObservation {
  private let id = UUID()
  private let handler: () -> Void
  
  init(handler: @escaping () -> Void) {
    self.handler = handler
  }
  
  func perform() {
    handler()
  }
}

extension IdentifiableObservation: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

extension IdentifiableObservation: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
