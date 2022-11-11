//===----------------------------------------------------------------------===//
//
// Handler.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Foundation

/// The existential type for an identifiable wrapper around a block of code.
protocol HandlerWrapper: Equatable, Hashable {
  associatedtype Value
  
  /// The identifying element of the handler.
  var id: AnyHashable { get }
  
  /// Creates a handler with the given identifier and code block.
  init(id: AnyHashable, block: @escaping () -> Value)
  
  /// Performs the handler's code block.
  func perform() -> Value
}

extension HandlerWrapper {
  /// Creates a handler with the given code block.
  init(block: @escaping () -> Value) {
    self.init(id: UUID(), block: block)
  }
}

extension HandlerWrapper {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

extension HandlerWrapper {
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

/// A concrete type for an identifiable wrapper around a block of code.
struct Handler<Value>: HandlerWrapper {
  let id: AnyHashable
  private let block: () -> Value
  
  init(id: AnyHashable, block: @escaping () -> Value) {
    self.id = id
    self.block = block
  }
  
  func perform() -> Value {
    block()
  }
}

/// An alias for an identifiable wrapper around a block of code whose
/// return value is `Void`.
typealias VoidHandler = Handler<Void>

extension Collection where Element: HandlerWrapper {
  /// Performs every handler in the collection and returns the results.
  @discardableResult
  func performAll() -> [Element.Value] {
    map { $0.perform() }
  }
}
