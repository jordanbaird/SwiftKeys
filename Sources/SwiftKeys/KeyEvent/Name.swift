//===----------------------------------------------------------------------===//
//
// Name.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

extension KeyEvent {
  /// A type that represents the name of a key event.
  ///
  /// Key events are automatically stored in the `UserDefaults` system once they have been
  /// registered. The value of the event's `name` property (an instance of this type) is
  /// used as the key. You can set the name's `prefix` property to help distinguish which
  /// system, or part of the app the name is being used in. For example, you might use
  /// "Key" to indicate that the name is associated with a key event.
  ///
  /// ```swift
  /// extension KeyEvent.Name {
  ///     // "KeyOpenPreferences" will be the full defaults key.
  ///     static let openPreferences = Self("OpenPreferences", prefix: "Key")
  /// }
  /// ```
  ///
  /// You can also provide a custom implementation of the `sharedPrefix` property of
  /// the `Prefix` type. Every event name that is created will use this prefix unless
  /// explicitly stated otherwise.
  ///
  /// ```swift
  /// extension KeyEvent.Name.Prefix {
  ///     static var sharedPrefix: Self { "SwiftKeys" }
  /// }
  /// extension KeyEvent.Name {
  ///     // "SwiftKeysQuitApp" will be the full defaults key.
  ///     static let quitApp = Self("QuitApp")
  /// }
  /// ```
  public struct Name: ExpressibleByStringInterpolation {
    /// The raw value of the name.
    public let rawValue: String
    
    private var truePrefix: PrefixValueType
    
    /// A prefix that will be applied to the name when it is stored in `UserDefaults`.
    /// 
    /// By default, this value is set to the `sharedPrefix` property -- an empty string.
    /// However, it can be set to any value desired.
    ///
    /// - Note: You can extend the `Prefix` type and provide a custom implementation of
    /// the `sharedPrefix` property to automatically apply that prefix to every event
    /// name that is created.
    public var prefix: Prefix {
      .init(truePrefix.rawValue)
    }
    
    /// The name's raw value, combined with its prefix.
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

extension KeyEvent.Name: CustomStringConvertible {
  public var description: String {
    "\(Self.self)(" + combinedValue + ")"
  }
}

extension KeyEvent.Name: Codable { }

extension KeyEvent.Name: Equatable { }

extension KeyEvent.Name: Hashable { }
