//===----------------------------------------------------------------------===//
//
// Name.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

extension KeyCommand {
  /// A type that represents the name of a key command.
  ///
  /// Key commands are automatically stored in the `UserDefaults` system once
  /// they have been registered. The value of the command's
  /// ``KeyCommand/name-swift.property`` property is used as the key. You can
  /// set the name's ``prefix-swift.property`` property to help differentiate
  /// between command types. For example, you might use "Command" to indicate
  /// that the name is associated with a key command.
  ///
  /// ```swift
  /// extension KeyCommand.Name {
  ///     // "CommandOpenPreferences" will be the full UserDefaults key.
  ///     static let openPreferences = Self("OpenPreferences", prefix: "Command")
  /// }
  /// ```
  ///
  /// You can also provide a custom implementation of the static `sharedPrefix`
  /// property of the `Prefix` type. Every name that is created will
  /// automatically use this prefix unless explicitly stated otherwise. By
  /// default, the value of `sharedPrefix` is an empty string.
  ///
  /// ```swift
  /// extension KeyCommand.Name.Prefix {
  ///     static var sharedPrefix: Self { "SwiftKeys" }
  /// }
  ///
  /// extension KeyCommand.Name {
  ///     // "SwiftKeysQuitApp" will be the full UserDefaults key.
  ///     static let quitApp = Self("QuitApp")
  /// }
  /// ```
  public struct Name: ExpressibleByStringInterpolation {
    /// The raw value of the name.
    public let rawValue: String

    /// A string that separates the name's `rawValue` from its `prefix`
    /// when the name is combined in the `combinedValue` property.
    public let separator: String

    private var prefixBase: Prefix.Base

    /// A prefix that will be applied to the name when it is stored in
    /// `UserDefaults`.
    ///
    /// By default, this value is set to the `sharedPrefix` property of
    /// the `Prefix` type. However, it can be set to any value desired
    /// through `Name`'s initializer.
    ///
    /// - Note: You can extend the `Prefix` type and override its `sharedPrefix`
    ///   property to automatically apply a custom prefix to every name that
    ///   doesn't explicitly define its own prefix.
    public var prefix: Prefix {
      .init(prefixBase.rawValue)
    }

    /// The name's raw value, combined with its ``prefix-swift.property`` and
    /// separated by its ``separator``.
    ///
    /// ```swift
    /// let name = KeyCommand.Name("Toggle", prefix: "Trigger", separator: "_")
    ///
    /// print(name.combinedValue)
    /// // Prints "Trigger_Toggle"
    /// ```
    public var combinedValue: String {
      prefixBase.rawValue + separator + rawValue
    }

    private init(rawValue: String, prefixBase: Prefix.Base, separator: String) {
      self.prefixBase = prefixBase
      self.rawValue = rawValue
      self.separator = separator
    }

    /// Creates a name with the given raw value, prefix, and separator.
    public init(_ rawValue: String, prefix: Prefix = .sharedPrefix, separator: String) {
      self.init(rawValue: rawValue, prefixBase: .init(prefix: prefix), separator: separator)
    }

    /// Creates a name with the given raw value and prefix.
    public init(_ rawValue: String, prefix: Prefix = .sharedPrefix) {
      self.init(rawValue, prefix: prefix, separator: "")
    }

    /// Creates a name from another name, using the given prefix
    /// and separator.
    ///
    /// If `prefix` is `nil`, the prefix belonging to `name` will
    /// be used.
    public init(_ name: Self, prefix: Prefix? = nil, separator: String) {
      if let prefix = prefix {
        self.init(name.rawValue, prefix: prefix, separator: separator)
      } else {
        self.init(name.rawValue, prefix: name.prefix, separator: separator)
      }
    }

    /// Creates a name from another name, using the given prefix.
    ///
    /// If `prefix` is `nil`, the prefix belonging to `name` will
    /// be used.
    public init(_ name: Self, prefix: Prefix? = nil) {
      self.init(name, prefix: prefix, separator: "")
    }

    /// Creates a name using a string literal.
    public init(stringLiteral value: String) {
      self.init(value)
    }
  }
}

extension KeyCommand.Name: Codable { }

extension KeyCommand.Name: CustomStringConvertible {
  public var description: String {
    combinedValue
  }
}

extension KeyCommand.Name: CustomDebugStringConvertible {
  public var debugDescription: String {
    "\(Self.self)("
    + "rawValue: \(rawValue), "
    + "prefix: \(prefixBase), "
    + "separator: \(separator)"
    + ")"
  }
}

extension KeyCommand.Name: Equatable { }

extension KeyCommand.Name: Hashable { }
