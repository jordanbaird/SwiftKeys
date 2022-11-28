//===----------------------------------------------------------------------===//
//
// Prefix.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

extension KeyCommand.Name {
  /// A prefix that is applied to a key command's name when stored in `UserDefaults`.
  public struct Prefix {
    /// The raw value of the prefix.
    public let rawValue: String

    /// Creates a prefix with the given raw value.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Creates a prefix with the given raw value.
    public init(_ rawValue: String) {
      self.init(rawValue: rawValue)
    }
  }
}

extension KeyCommand.Name.Prefix: Codable { }

extension KeyCommand.Name.Prefix: CustomStringConvertible {
  /// A textual representation of the prefix.
  public var description: String { rawValue }
}

extension KeyCommand.Name.Prefix: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue == rhs.rawValue
  }
}

extension KeyCommand.Name.Prefix: ExpressibleByStringInterpolation {
  /// Creates a prefix from a string literal.
  public init(stringLiteral value: String) {
    self.init(rawValue: value)
  }
}

extension KeyCommand.Name.Prefix: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

extension KeyCommand.Name.Prefix: RawRepresentable { }
