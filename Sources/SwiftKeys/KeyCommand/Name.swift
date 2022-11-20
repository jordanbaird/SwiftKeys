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

    private var truePrefix: PrefixValueType

    /// A prefix that will be applied to the name when it is stored in
    /// `UserDefaults`.
    ///
    /// By default, this value is set to the `sharedPrefix` property of the
    /// `Prefix` type. However, it can be set to any value desired, either
    /// through `Name`'s initializer, or by setting this property directly.
    ///
    /// - Note: You can extend the `Prefix` type and override its `sharedPrefix`
    ///   property to automatically apply a custom prefix to every name that
    ///   doesn't explicitly define its own prefix.
    public var prefix: Prefix {
      get { .init(truePrefix.rawValue) }
      set { truePrefix = .init(prefix: newValue) }
    }

    /// The name's raw value, combined with its prefix.
    ///
    /// ```swift
    /// let name = KeyCommand.Name("Toggle", prefix: "Trigger")
    ///
    /// print(name.combinedValue)
    /// // Prints "TriggerToggle"
    /// ```
    public var combinedValue: String {
      prefix.rawValue + rawValue
    }

    /// Creates a name with the given raw value and prefix.
    public init(_ rawValue: String, prefix: Prefix = .sharedPrefix) {
      truePrefix = .init(prefix: prefix)
      self.rawValue = rawValue
    }

    /// Creates a name using a string literal.
    public init(stringLiteral value: String) {
      self.init(value)
    }
  }
}

extension KeyCommand.Name: CustomStringConvertible {
  public var description: String {
    "\(Self.self)(" + combinedValue + ")"
  }
}

extension KeyCommand.Name: Codable { }

extension KeyCommand.Name: Equatable { }

extension KeyCommand.Name: Hashable { }
