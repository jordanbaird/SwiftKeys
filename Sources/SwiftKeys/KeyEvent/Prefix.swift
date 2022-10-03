//===----------------------------------------------------------------------===//
//
// Prefix.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Foundation // To enable `@objc dynamic` declarations

// MARK: - _Prefix (Implementation)

public class _Prefix: Codable, ExpressibleByStringInterpolation, CustomStringConvertible {
  
  // MARK: - Static Properties
  
  /// A prefix whose value is an empty string.
  public static var emptyPrefix: Self {
    .init("")
  }
  
  /// The prefix that all ``KeyEvent/Name-swift.struct`` instances will
  /// automatically use.
  ///
  /// This version of the property is mostly an implementation detail, and is here
  /// to allow for a more flexible API. For example, with this property, one could
  /// initialize a name like this:
  ///
  /// ```swift
  /// let name = KeyEvent.Name("SomeName", prefix: .sharedPrefix)
  /// ```
  public static var sharedPrefix: Self {
    emptyPrefix.sharedPrefix
  }
  
  // MARK: - Instance Properties
  
  /// The raw value of the prefix.
  public let rawValue: String
  
  /// A string representation of the prefix.
  public var description: String {
    "\(Self.self)(" + rawValue + ")"
  }
  
  /// The prefix that all ``KeyEvent/Name-swift.struct`` instances will
  /// automatically use.
  ///
  /// The default implementation of this property returns an instance containing
  /// an empty string. You can provide a custom implementation that is unique to
  /// your app.
  ///
  /// ```swift
  /// public override var sharedPrefix: Self {
  ///     Self("Watermelon")
  /// }
  /// // Now, every instance of `KeyEvent.Name` will have the
  /// // prefix "Watermelon".
  /// ```
  @objc dynamic
  open var sharedPrefix: Self {
    .init("")
  }
  
  // MARK: - Initializers
  
  /// Creates a prefix with the given raw value.
  public required init(_ rawValue: String) {
    self.rawValue = rawValue
  }
  
  /// Creates a prefix using a string literal.
  public required convenience init(stringLiteral value: String) {
    self.init(value)
  }
}

extension _Prefix: Equatable {
  public static func == (lhs: _Prefix, rhs: _Prefix) -> Bool {
    lhs.rawValue == rhs.rawValue
  }
}

extension _Prefix: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

// MARK: - Prefix

extension KeyEvent.Name {
  public final class Prefix: _Prefix { }
}

// MARK: - PrefixValueType

struct PrefixValueType {
  let rawValue: String
  
  init(prefix: KeyEvent.Name.Prefix) {
    self.rawValue = prefix.rawValue
  }
}

extension PrefixValueType: Codable { }

extension PrefixValueType: Equatable { }

extension PrefixValueType: Hashable { }
