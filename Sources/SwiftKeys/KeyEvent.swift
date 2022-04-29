//===----------------------------------------------------------------------===//
//
// KeyEvent.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Cocoa

/// An observable key event.
///
/// Create a key event by calling one of its initializers. You can then use it
/// to initialize a `KeyRecorder` instance, which will update the event whenever
/// a new key combination is recorded. You can also observe the event, and
/// perform actions on both key-down _and_ key-up.
///
/// ```swift
/// let event = KeyEvent(name: "SomeEvent")
/// let recorder = KeyRecorder(keyEvent: event)
///
/// event.observe(.keyDown) {
///     print("DOWN")
/// }
/// event.observe(.keyUp) {
///     print("UP")
/// }
/// ```
///
/// You can also initialize an event with a predefined key and modifiers. In
/// the following example, the key recorder that is created will have starting
/// value of "⇧⌥␣" (Shift-Option-Space).
///
/// ```swift
/// let event = KeyEvent(
///     name: "SomeEvent",
///     key: .space,
///     modifiers: [.shift, .option])
///
/// let recorder = KeyRecorder(keyEvent: event)
/// ```
///
/// If a key event is created with the same name as one that has been created
/// previously, both events will now reference the same underlying object.
///
/// ```swift
/// let originalEvent = KeyEvent(
///     name: "SomeEvent",
///     key: .space,
///     modifiers: [.shift, .option])
///
/// let duplicateEvent = KeyEvent(name: "SomeEvent")
///
/// print(originalEvent == duplicateEvent) // Prints: "true".
/// print(duplicateEvent.key) // Prints: "space".
/// print(duplicateEvent.modifiers) // Prints: "shift, option".
/// ```
///
/// If the example above were to provide a new key and new modifiers in
/// `duplicateEvent`'s initializer, both `duplicateEvent` _and_ `originalEvent`
/// have those values.
///
/// ```swift
/// let originalEvent = KeyEvent(
///     name: "SomeEvent",
///     key: .space,
///     modifiers: [.shift, .option])
///
/// let duplicateEvent = KeyEvent(
///     name: "SomeEvent",
///     key: .leftArrow,
///     modifiers: [.control, .command])
///
/// print(originalEvent == duplicateEvent) // Prints: "true".
/// print(originalEvent.key) // Prints: "leftArrow".
/// print(originalEvent.modifiers) // Prints: "control, command".
/// ```
public struct KeyEvent {
  enum CodingKeys: CodingKey {
    case key
    case modifiers
    case name
  }
  
  static var keyEventStorage = [Name: KeyEvent]()
  static var proxyStorage = [Name: EventProxy]()
  
  /// The key associated with this key event.
  public var key: Key? {
    proxy.key
  }
  
  /// The modifier keys associated with this key event.
  public var modifiers: [Modifier] {
    proxy.modifiers
  }
  
  /// The name that is be used to store this key event.
  public let name: Name
  
  var proxy: EventProxy {
    if let proxy = Self.proxyStorage[name] {
      return proxy
    } else {
      let proxy = EventProxy(name: name)
      Self.proxyStorage[name] = proxy
      return proxy
    }
  }
  
  // Implementation detail:
  private init?(_name: Name) {
    if
      let data = UserDefaults.standard.data(forKey: _name.combinedValue),
      let event = try? JSONDecoder().decode(Self.self, from: data)
    {
      self = event
    } else {
      return nil
    }
  }
  
  /// Creates a key event with the given name.
  public init(name: Name) {
    if let event = Self.keyEventStorage[name] {
      self = event
    } else if let event = Self(_name: name) {
      self = event
    } else {
      self.name = name
    }
    Self.keyEventStorage[name] = self
  }
  
  /// Creates a key event with the given name, keys, and modifiers.
  public init(name: Name, key: Key, modifiers: [Modifier]) {
    self.init(name: name)
    proxy.mutateWithoutChangingRegistrationState {
      $0.key = key
      $0.modifiers = modifiers
    }
  }
  
  /// Creates a key event with the given name, keys, and modifiers.
  public init(name: Name, key: Key, modifiers: Modifier...) {
    self.init(name: name, key: key, modifiers: modifiers)
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(Name.self, forKey: .name)
    try proxy.mutateWithoutChangingRegistrationState {
      $0.key = try container.decode(Key.self, forKey: .key)
      $0.modifiers = try container.decode([Modifier].self, forKey: .modifiers)
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(key, forKey: .key)
    try container.encode(modifiers, forKey: .modifiers)
    try container.encode(name, forKey: .name)
  }
  
  /// Observes the key event, and executes the provided handler when the event
  /// is triggered. This method can be called multiple times. Each handler that
  /// is added to the event will be executed synchronously in the order in which
  /// they were added.
  public func observe(_ type: EventType, handler: @escaping () -> Void) {
    proxy.observations.append((type: type, handler: handler))
    proxy.register()
  }
}

extension KeyEvent: Codable { }

extension KeyEvent: Equatable { }

extension KeyEvent: Hashable { }
