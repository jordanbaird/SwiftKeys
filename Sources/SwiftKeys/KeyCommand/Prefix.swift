//===----------------------------------------------------------------------===//
//
// Prefix.swift
//
//===----------------------------------------------------------------------===//

extension KeyCommand.Name {
    /// A prefix that is applied to a key command's name when stored in `UserDefaults`.
    public struct Prefix {
        /// The raw value of the prefix.
        public let rawValue: String

        /// ** Internal use only **
        private init(_rawValue: String) {
            self.rawValue = _rawValue
        }

        /// Creates a prefix with the given raw value.
        public init(_ rawValue: String) {
            self.init(_rawValue: rawValue)
        }
    }
}

// MARK: Codable
extension KeyCommand.Name.Prefix: Codable { }

// MARK: CustomStringConvertible
extension KeyCommand.Name.Prefix: CustomStringConvertible {
    /// A textual representation of the prefix.
    public var description: String { rawValue }
}

// MARK: Equatable
extension KeyCommand.Name.Prefix: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

// MARK: ExpressibleByStringInterpolation
extension KeyCommand.Name.Prefix: ExpressibleByStringInterpolation {
    /// Creates a prefix from a string literal.
    public init(stringLiteral value: String) {
        self.init(_rawValue: value)
    }
}

// MARK: Hashable
extension KeyCommand.Name.Prefix: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

// MARK: RawRepresentable
extension KeyCommand.Name.Prefix: RawRepresentable {
    /// Creates a prefix with the given raw value.
    public init(rawValue: String) {
        self.init(_rawValue: rawValue)
    }
}
