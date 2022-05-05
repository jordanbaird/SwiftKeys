//===----------------------------------------------------------------------===//
//
// KeyEvent.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox
import Cocoa

public struct KeyEvent {
  enum CodingKeys: CodingKey {
    case key
    case modifiers
    case name
  }
  
  /// Constants that specify the type of a key event.
  ///
  /// Pass these into a key event's `observe(_:handler:)` method. The closure you
  /// provide in that method will be called whenever an event of this type is posted.
  ///
  /// ```swift
  /// let event = KeyEvent(
  ///     name: "Cheese",
  ///     key: .leftArrow,
  ///     modifiers: [.command, .option])
  ///
  /// event.observe(.keyDown) {
  ///     print("KEY DOWN")
  /// }
  ///
  /// event.observe(.keyUp) {
  ///     print("KEY UP")
  /// }
  ///
  /// // Note that `observe(_:handler:)` can be called multiple
  /// // times, each invoking different closures.
  /// ```
  public enum EventType {
    /// The key is released.
    case keyUp
    /// The key is pressed.
    case keyDown
    
    init(_ eventRef: EventRef!) {
      switch Int(GetEventKind(eventRef)) {
      case kEventHotKeyPressed: self = .keyDown
      case kEventHotKeyReleased: self = .keyUp
      default: fatalError("Invalid event reference.")
      }
    }
  }
  
  static var keyEventStorage = [Name: KeyEvent]()
  
  /// The name that is used to store this key event.
  public let name: Name
  
  /// A Boolean value that indicates whether the key event is currently enabled and active.
  ///
  /// When enabled, the event's handlers will be executed whenever the event is triggered.
  ///
  /// - Note: If the event does not have a key or modifiers, it will not be possible to
  /// enable it, even when calling ``enable()``. If you have created an event without these,
  /// and wish to enable it, you can create a new event with the same name, and it will take
  /// the place of the old event.
  public var isEnabled: Bool {
    proxy.isRegistered
  }
  
  /// The key associated with this key event.
  public var key: Key? {
    proxy.key
  }
  
  /// The modifier keys associated with this key event.
  public var modifiers: [Modifier] {
    proxy.modifiers
  }
  
  var proxy: EventProxy {
    if let proxy = ProxyStorage.proxy(with: name) {
      return proxy
    } else {
      let proxy = EventProxy(name: name)
      ProxyStorage.store(proxy)
      return proxy
    }
  }
  
  // Implementation.
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
  
  /// Creates a key event from the given decoder.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(Name.self, forKey: .name)
    try proxy.mutateWithoutChangingRegistrationState {
      $0.key = try container.decode(Key.self, forKey: .key)
      $0.modifiers = try container.decode([Modifier].self, forKey: .modifiers)
    }
  }
  
  /// Encodes a key event to the given encoder.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(key, forKey: .key)
    try container.encode(modifiers, forKey: .modifiers)
    try container.encode(name, forKey: .name)
  }
  
  /// Observes the key event, and executes the provided handler when the event
  /// is triggered.
  ///
  /// This method can be called multiple times. Each handler that is added to
  /// the event will be executed synchronously in the order in which they were
  /// added.
  ///
  /// You can pass the returned ``Observation`` instance into the ``removeObservation(_:)``
  /// method, or similar, to remove it from the event. This will stop the execution of
  /// the observation's handler.
  @discardableResult
  public func observe(_ type: EventType, handler: @escaping () -> Void) -> Observation {
    let observation = Observation(eventType: type, value: handler)
    proxy.observations.append(observation)
    proxy.register()
    return observation
  }
  
  /// Removes the given observation from the key event.
  ///
  /// Once an observation is removed, its handler will no longer be executed.
  public func removeObservation(_ observation: Observation) {
    proxy.observations.removeAll { $0 == observation }
  }
  
  /// Removes the given observations from the key event.
  ///
  /// Once an observation is removed, its handler will no longer be executed.
  public func removeObservations(_ observations: [Observation]) {
    for observation in observations {
      removeObservation(observation)
    }
  }
  
  /// Removes every observation that matches the given predicate from the key event.
  ///
  /// Once an observation is removed, its handler will no longer be executed.
  public func removeObservations(where shouldRemove: (Observation) throws -> Bool) rethrows {
    for observation in proxy.observations {
      if try shouldRemove(observation) {
        removeObservation(observation)
      }
    }
  }
  
  /// Removes every observation from the key event.
  ///
  /// Once an observation is removed, its handler will no longer be executed.
  public func removeAllObservations() {
    proxy.observations.removeAll()
  }
  
  /// Enables the key event.
  ///
  /// When enabled, the key event's observation handlers become active, and will
  /// execute whenever the event is triggered.
  public func enable() {
    proxy.register()
  }
  
  /// Disables the key event.
  ///
  /// When disabled, the key event's observation handlers become dormant, but are
  /// still retained, so that the event can be re-enabled later. If you wish to
  /// completely remove the event and its handlers, use the ``remove()`` method instead.
  public func disable() {
    proxy.unregister()
  }
  
  /// Completely removes the key event and its handlers.
  ///
  /// Once this method has been called, the key event should be considered invalid.
  /// The ``enable()`` method will have no effect. If you wish to re-enable the event,
  /// you will need to call ``observe(_:handler:)`` and provide a new handler.
  public func remove() {
    proxy.unregister()
    ProxyStorage.remove(proxy)
  }
}

extension KeyEvent: Codable { }

extension KeyEvent: Equatable { }

extension KeyEvent: Hashable { }
