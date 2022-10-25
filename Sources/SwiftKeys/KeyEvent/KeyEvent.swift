//===----------------------------------------------------------------------===//
//
// KeyEvent.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox
import Foundation

public struct KeyEvent {
  private enum CodingKeys: CodingKey {
    case key
    case modifiers
    case name
  }
  
  static var reservedHotKeys: [[String: Any]] {
    var reservedHotKeys: Unmanaged<CFArray>?
    let status = CopySymbolicHotKeys(&reservedHotKeys)
    guard status == noErr else {
      EventError.systemRetrievalFailed(code: status).log()
      return []
    }
    return reservedHotKeys?.takeRetainedValue() as? [[String: Any]] ?? []
  }
  
  /// The name that is used to store the event.
  public let name: Name
  
  /// The underlying object associated with the event.
  var proxy: EventProxy {
    if let proxy = ProxyStorage.proxy(with: name) {
      return proxy
    } else {
      let proxy = EventProxy(name: name)
      ProxyStorage.store(proxy)
      return proxy
    }
  }
  
  /// A Boolean value that indicates whether the event is currently
  /// enabled and active.
  ///
  /// When enabled, the event's handlers will be executed whenever the
  /// event is triggered.
  ///
  /// - Note: If the event does not have a key or modifiers, it will not
  ///   be possible to enable it, even when calling ``enable()``. If you have
  ///   created an event without these, and wish to enable it, you can create
  ///   a new event with the same name, and it will take the place of the old
  ///   event.
  public var isEnabled: Bool {
    proxy.isRegistered
  }
  
  /// The key associated with the event.
  public var key: Key? {
    proxy.key
  }
  
  /// The modifier keys associated with the event.
  public var modifiers: [Modifier] {
    proxy.modifiers
  }
  
  /// Creates a key event with the given name.
  ///
  /// If an event has already been created with the same name, this event will
  /// be initialized with a reference to the existing event's underlying object.
  public init(name: Name) {
    if
      ProxyStorage.proxy(with: name) == nil,
      let data = UserDefaults.standard.data(forKey: name.combinedValue),
      let event = try? JSONDecoder().decode(Self.self, from: data)
    {
      self = event
    } else {
      self.name = name
    }
  }
  
  /// Creates a key event with the given name, keys, and modifiers.
  ///
  /// If an event has already been created with the same name, this event will
  /// be initialized with a reference to the existing event's underlying object.
  ///
  /// - Note: The underlying object's key and modifiers will be updated to
  ///   match the ones provided in this initializer. If this behavior is undesired,
  ///   use ``init(name:)`` instead.
  public init(name: Name, key: Key, modifiers: [Modifier]) {
    self.init(name: name)
    proxy.mutateWithoutChangingRegistrationState {
      $0.key = key
      $0.modifiers = modifiers
    }
  }
  
  /// Creates a key event with the given name, keys, and modifiers.
  ///
  /// If an event has already been created with the same name, this event will
  /// be initialized with a reference to the existing event's underlying object.
  ///
  /// - Note: The underlying object's key and modifiers will be updated to
  ///   match the ones provided in this initializer. If this behavior is undesired,
  ///   use ``init(name:)`` instead.
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
  
  static func isReservedBySystem(key: Key, modifiers: [Modifier]) -> Bool {
    return reservedHotKeys.contains {
      if
        $0[kHISymbolicHotKeyEnabled] as? Bool == true,
        let keyCode = $0[kHISymbolicHotKeyCode] as? Int,
        let modifierCode = $0[kHISymbolicHotKeyModifiers] as? Int,
        let reservedKey = Key(keyCode),
        let reservedModifiers = [Modifier](carbonModifiers: modifierCode)
      {
        return key == reservedKey && modifiers == reservedModifiers
      }
      return false
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(key, forKey: .key)
    try container.encode(modifiers, forKey: .modifiers)
    try container.encode(name, forKey: .name)
  }
  
  /// Adds the given observation to the key event, if the event does not
  /// already contain it.
  ///
  /// When the event is triggered, the observations that belong to the
  /// event will be executed synchronously in the order they were added.
  public func addObservation(_ observation: Observation) {
    if !proxy.eventObservations.contains(observation) {
      proxy.eventObservations.append(observation)
      proxy.register()
    }
  }
  
  /// Observes the key event, and executes the provided handler when the
  /// event is triggered.
  ///
  /// This method can be called multiple times. When the event is triggered,
  /// the observations that belong to the event will be executed synchronously
  /// in the order they were added.
  ///
  /// You can pass the returned ``Observation`` instance into the ``removeObservation(_:)``
  /// method or similar to remove the observation and stop the execution of its handler.
  @discardableResult
  public func observe(_ type: EventType, handler: @escaping () -> Void) -> Observation {
    let observation = Observation(eventType: type, value: handler)
    addObservation(observation)
    return observation
  }
  
  /// Removes the given observation.
  ///
  /// Pass an instance of ``Observation`` that you received from a call to
  /// ``observe(_:handler:)``. The observation must belong to this key event.
  /// Once the observation has been removed, its handler will no longer be executed.
  public func removeObservation(_ observation: Observation) {
    proxy.eventObservations.removeAll { $0 == observation }
  }
  
  /// Removes the given observations.
  ///
  /// Pass instances of ``Observation`` that you received from calls to
  /// ``observe(_:handler:)``. The observation must belong to this key event.
  /// Once the observations have been removed, their handlers will no longer be executed.
  public func removeObservations(_ observations: [Observation]) {
    for observation in observations {
      removeObservation(observation)
    }
  }
  
  /// Removes the first observation that matches the given predicate.
  ///
  /// Use this method if you need to remove an instance of ``Observation``
  /// that you don't have access to. This example removes the first observation
  /// for the ``EventType/keyDown`` event type:
  ///
  /// ```swift
  /// let event = KeyEvent(name: someName)
  /// event.removeFirstObservation(where: { $0.eventType == .keyDown })
  /// ```
  ///
  /// Only observations belonging to this key event will be considered for removal.
  /// Once the observation has been removed, its handler will no longer be executed.
  public func removeFirstObservation(where shouldRemove: (Observation) throws -> Bool) rethrows {
    if let index = try proxy.eventObservations.firstIndex(where: shouldRemove) {
      proxy.eventObservations.remove(at: index)
    }
  }
  
  /// Removes every observation that matches the given predicate.
  ///
  /// Use this method if you need to remove multiple ``Observation`` instances
  /// that you don't have access to. This example removes all observations for
  /// the ``EventType/keyDown`` event type:
  ///
  /// ```swift
  /// let event = KeyEvent(name: someName)
  /// event.removeObservations(where: { $0.eventType == .keyDown })
  /// ```
  ///
  /// Only observations belonging to this key event will be considered for removal.
  /// Once the observations have been removed, their handlers will no longer be executed.
  public func removeObservations(where shouldRemove: (Observation) throws -> Bool) rethrows {
    try proxy.eventObservations.removeAll(where: shouldRemove)
  }
  
  /// Removes all observations from the key event.
  ///
  /// Once the observations have been removed, their handlers will no longer be executed.
  public func removeAllObservations() {
    proxy.eventObservations.removeAll()
  }
  
  /// Enables the key event.
  ///
  /// When enabled, the key event's observation handlers become active, and will
  /// be executed whenever the event is triggered. Note that calling ``observe(_:handler:)``
  /// automatically enables the event.
  public func enable() {
    proxy.register()
  }
  
  /// Disables the key event.
  ///
  /// When disabled, the key event's observation handlers become dormant, but are
  /// retained, so that the event can be re-enabled later. If you wish to completely
  /// remove the event and its handlers, use the ``remove()`` method instead.
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
  
  /// Runs the key event's observation handlers for the given event type.
  ///
  /// ```swift
  /// let event = KeyEvent(
  ///     name: "SomeName",
  ///     key: .space,
  ///     modifiers: [.shift, .command]
  /// )
  ///
  /// event.observe(.keyDown) {
  ///     print("'Shift + Command + Space' was pressed.")
  /// }
  /// event.observe(.keyUp) {
  ///     print("'Shift + Command + Space' was released.")
  /// }
  ///
  /// event.runHandlers(for: .keyDown)
  /// // Prints: 'Shift + Command + Space' was pressed.
  ///
  /// event.runHandlers(for: .keyUp)
  /// // Prints: 'Shift + Command + Space' was released.
  /// ```
  public func runHandlers(for eventType: EventType) {
    proxy.performObservations(matching: eventType)
  }
  
  /// Runs the key event's observation handlers that match the given predicate.
  ///
  /// ```swift
  /// let event = KeyEvent(
  ///     name: "SomeName",
  ///     key: .space,
  ///     modifiers: [.shift, .command]
  /// )
  ///
  /// event.observe(.keyDown) {
  ///     print("'Shift + Command + Space' was pressed.")
  /// }
  /// event.observe(.keyUp) {
  ///     print("'Shift + Command + Space' was released.")
  /// }
  ///
  /// event.runHandlers {
  ///     $0.eventType == .keyDown || $0.eventType == .keyUp
  /// }
  ///
  /// // Prints:
  /// //   'Shift + Command + Space' was pressed.
  /// //   'Shift + Command + Space' was released.
  /// ```
  public func runHandlers(where predicate: (Observation) throws -> Bool) rethrows {
    for observation in proxy.eventObservations where try predicate(observation) {
      observation.handler()
    }
  }
}

extension KeyEvent: Codable { }

extension KeyEvent: CustomStringConvertible {
  public var description: String {
    var keyString = "nil"
    if let key = key {
      keyString = "\(key)"
    }
    return "\(Self.self)("
    + "name: \(name), "
    + "key: \(keyString), "
    + "modifiers: \(modifiers))"
  }
}

extension KeyEvent: Equatable { }

extension KeyEvent: Hashable { }
