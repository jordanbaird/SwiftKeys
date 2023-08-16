//
//  Name.swift
//  SwiftKeys
//

// MARK: - KeyCommand Name

extension KeyCommand {
    /// A type that represents the name of a key command.
    ///
    /// Key commands are automatically stored in the `UserDefaults` system using
    /// their ``KeyCommand/name-swift.property`` property. You can provide a custom
    /// prefix to help differentiate between command types. For example, you might
    /// use "Settings" to indicate that the name is associated with a setting.
    ///
    /// ```swift
    /// extension KeyCommand.Name {
    ///     // "OpenApp" will be the full UserDefaults key.
    ///     static let openApp = Self("OpenApp")
    ///
    ///     // "SettingsToggleVisibility" will be the full UserDefaults key.
    ///     static let toggleVisibility = Self("ToggleVisibility", prefix: "Settings")
    /// }
    /// ```
    ///
    /// You can define static names and prefixes for better type safety.
    ///
    /// ```swift
    /// extension KeyCommand.Name.Prefix {
    ///     static let settings = Self("Settings")
    ///     static let app = Self("MyGreatApp")
    /// }
    ///
    /// extension KeyCommand.Name {
    ///     // "Settings_Open" will be the full UserDefaults key.
    ///     static let openSettings = Self("Open", prefix: .settings, separator: "_")
    ///
    ///     // "MyGreatApp_Quit" will be the full UserDefaults key.
    ///     static let quitApp = Self("Quit", prefix: .app, separator: "_")
    /// }
    /// ```
    public struct Name {

        // MARK: Properties

        /// The raw value of the name.
        public let rawValue: String

        /// A prefix that will be applied to the name when it is stored in `UserDefaults`.
        public let prefix: Prefix

        /// A string that separates the name's raw value from its prefix when the name is
        /// combined in the `combinedValue` property.
        public let separator: String

        /// The name's raw value, combined with its prefix and separated by its separator.
        ///
        /// ```swift
        /// let name = KeyCommand.Name("Toggle", prefix: "Trigger", separator: "_")
        ///
        /// print(name.combinedValue)
        /// // Prints "Trigger_Toggle"
        /// ```
        public var combinedValue: String {
            prefix.rawValue + separator + rawValue
        }

        // MARK: Initializers

        /// Creates a name with the given raw value, prefix, and separator.
        public init(
            _ rawValue: @autoclosure () -> String,
            prefix: @autoclosure () -> Prefix = "",
            separator: @autoclosure () -> String = ""
        ) {
            self.rawValue = rawValue()
            self.prefix = prefix()
            self.separator = separator()
        }

        /// Creates a name from another name, using the given prefix and separator.
        ///
        /// If `prefix` is `nil`, the prefix belonging to `name` will be used.
        public init(
            _ name: @autoclosure () -> Self,
            prefix: @autoclosure () -> Prefix? = nil,
            separator: @autoclosure () -> String = ""
        ) {
            let name = name()
            let separator = separator()
            if let prefix = prefix() {
                self.init(name.rawValue, prefix: prefix, separator: separator)
            } else {
                self.init(name.rawValue, prefix: name.prefix, separator: separator)
            }
        }
    }
}

// MARK: Name: Codable
extension KeyCommand.Name: Codable { }

// MARK: Name: CustomDebugStringConvertible
extension KeyCommand.Name: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(Self.self)(" +
        "rawValue: \(rawValue), " +
        "prefix: \(prefix), " +
        "separator: \(separator)" +
        ")"
    }
}

// MARK: Name: CustomStringConvertible
extension KeyCommand.Name: CustomStringConvertible {
    public var description: String {
        combinedValue
    }
}

// MARK: Name: Equatable
extension KeyCommand.Name: Equatable { }

// MARK: Name: ExpressibleByStringInterpolation
extension KeyCommand.Name: ExpressibleByStringInterpolation {
    /// Creates a name using a string literal.
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: Name: Hashable
extension KeyCommand.Name: Hashable { }

// MARK: - Name Prefix

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

// MARK: Prefix: Codable
extension KeyCommand.Name.Prefix: Codable { }

// MARK: Prefix: CustomStringConvertible
extension KeyCommand.Name.Prefix: CustomStringConvertible {
    /// A textual representation of the prefix.
    public var description: String { rawValue }
}

// MARK: Prefix: Equatable
extension KeyCommand.Name.Prefix: Equatable { }

// MARK: Prefix: ExpressibleByStringInterpolation
extension KeyCommand.Name.Prefix: ExpressibleByStringInterpolation {
    /// Creates a prefix from a string literal.
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: Prefix: Hashable
extension KeyCommand.Name.Prefix: Hashable { }

// MARK: Prefix: RawRepresentable
extension KeyCommand.Name.Prefix: RawRepresentable { }
