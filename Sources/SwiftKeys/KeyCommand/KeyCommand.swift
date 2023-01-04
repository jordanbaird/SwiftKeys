//===----------------------------------------------------------------------===//
//
// KeyCommand.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox
import Cocoa

@available(*, deprecated, message: "Renamed to 'KeyCommand'", renamed: "KeyCommand")
public typealias KeyEvent = KeyCommand

public struct KeyCommand {

  // MARK: Nested types

  private enum CodingKeys: CodingKey {
    case key
    case modifiers
    case name
  }

  // MARK: Static properties

  static var reservedHotKeys: [[String: Any]] {
    var reservedHotKeys: Unmanaged<CFArray>?
    let status = CopySymbolicHotKeys(&reservedHotKeys)
    guard status == noErr else {
      KeyCommandError.systemRetrievalFailed(status: status).log()
      return []
    }
    return reservedHotKeys?.takeRetainedValue() as? [[String: Any]] ?? []
  }

  // MARK: Properties

  /// The name that is used to store the key command.
  public let name: Name

  /// The underlying proxy object associated with the key command,
  /// stored and retrieved using the key command's name.
  ///
  /// - Note: If no proxy object has been stored at the time of
  ///   access, a new object will be created and stored.
  var proxy: KeyCommandProxy {
    ProxyStorage.proxy(with: name) ?? KeyCommandProxy(with: name, storing: true)
  }

  private var trackingNotificationNamesAndBlocks: [(name: Notification.Name, blocks: [() -> Void])] {
    [
      (NSMenu.didBeginTrackingNotification, [{ proxy.menuIsOpen = true }, disable]),
      (NSMenu.didEndTrackingNotification, [{ proxy.menuIsOpen = false }, enable]),
    ]
  }

  /// A Boolean value that indicates whether the key command is currently
  /// enabled and active.
  ///
  /// When enabled, the key command's handlers will be executed whenever
  /// the command is triggered.
  ///
  /// - Note: If the command does not have a key or modifiers, it will not
  ///   be possible to enable it, even when calling ``enable()``. If you
  ///   have created a command without these, and wish to enable it, you
  ///   can create a new command with the same name, and it will take the
  ///   place of the existing one.
  public var isEnabled: Bool {
    proxy.isRegistered
  }

  /// The key associated with the key command.
  public var key: Key? {
    get { proxy.key }
    set { proxy.key = newValue }
  }

  /// The modifier keys associated with the key command.
  public var modifiers: [Modifier] {
    get { proxy.modifiers }
    set { proxy.modifiers = newValue }
  }

  /// A Boolean value that indicates whether the key command
  /// will be disabled when a menu belonging to the app opens.
  public var disablesOnMenuOpen: Bool {
    get {
      trackingNotificationNamesAndBlocks.allSatisfy {
        proxy.notificationCenterObserver.isObserving($0.name)
      }
    }
    nonmutating set {
      guard newValue != disablesOnMenuOpen else {
        return
      }
      if newValue {
        for tuple in trackingNotificationNamesAndBlocks {
          for block in tuple.blocks {
            proxy.notificationCenterObserver.observe(tuple.name, block: block)
          }
        }
      } else {
        for tuple in trackingNotificationNamesAndBlocks {
          proxy.notificationCenterObserver.removeObservations(for: tuple.name)
        }
      }
    }
  }

  // MARK: Initializers

  init(proxy: KeyCommandProxy) {
    name = proxy.name
  }

  /// Creates a key command with the given name.
  ///
  /// If a key command has already been created with the same name, this
  /// command will be initialized with a reference to the existing command's
  /// underlying object.
  public init(name: Name) {
    if
      ProxyStorage.proxy(with: name) == nil,
      let data = UserDefaults.standard.data(forKey: name.combinedValue),
      let command = try? JSONDecoder().decode(Self.self, from: data)
    {
      self = command
    } else {
      self.name = name
    }
  }

  /// Creates a key command with the given name, keys, and modifiers.
  ///
  /// If a key command has already been created with the same name, this
  /// command will be initialized with a reference to the existing command's
  /// underlying object.
  ///
  /// - Note: The underlying object's key and modifiers will be updated to
  ///   match the ones provided in this initializer. If this behavior is undesired,
  ///   use ``KeyCommand/init(name:)`` instead.
  public init(name: Name, key: Key, modifiers: [Modifier]) {
    self.init(name: name)
    proxy.withoutChangingRegistrationState {
      $0.key = key
      $0.modifiers = modifiers
    }
  }

  /// Creates a key command with the given name, keys, and modifiers.
  ///
  /// If a key command has already been created with the same name, this
  /// command will be initialized with a reference to the existing command's
  /// underlying object.
  ///
  /// - Note: The underlying object's key and modifiers will be updated to
  ///   match the ones provided in this initializer. If this behavior is undesired,
  ///   use ``KeyCommand/init(name:)`` instead.
  public init(name: Name, key: Key, modifiers: Modifier...) {
    self.init(name: name, key: key, modifiers: modifiers)
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(Name.self, forKey: .name)
    try proxy.withoutChangingRegistrationState {
      $0.key = try container.decode(Key.self, forKey: .key)
      $0.modifiers = try container.decode([Modifier].self, forKey: .modifiers)
    }
  }

  // MARK: Static methods

  static func isReservedBySystem(key: Key, modifiers: [Modifier]) -> Bool {
    reservedHotKeys.contains {
      guard
        let isEnabled = $0[kHISymbolicHotKeyEnabled] as? Bool,
        isEnabled,
        let keyCode = $0[kHISymbolicHotKeyCode] as? Int,
        let modifierCode = $0[kHISymbolicHotKeyModifiers] as? UInt32
      else {
        return false
      }

      let reservedModifiers = [Modifier](carbonModifiers: modifierCode)

      guard
        modifiers.count == reservedModifiers.count,
        key == Key(rawValue: keyCode)
      else {
        return false
      }

      return modifiers.allSatisfy {
        reservedModifiers.contains($0)
      }
    }
  }

  // MARK: Methods

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(key, forKey: .key)
    try container.encode(modifiers, forKey: .modifiers)
    try container.encode(name, forKey: .name)
  }

  /// Adds the given observation to the key command, if the command does
  /// not already contain it.
  ///
  /// When the command is triggered, the observations attached to it will
  /// be executed synchronously in the order they were added.
  ///
  /// You typically shouldn't need to use this method;
  /// prefer ``observe(_:handler:)``.
  public func addObservation(_ observation: Observation) {
    if !proxy.keyCommandObservations.contains(observation) {
      proxy.keyCommandObservations.append(observation)
      proxy.register()
    }
  }

  /// Observes the key command, and executes the provided handler whenever
  /// it is triggered.
  ///
  /// This method can be called multiple times. When the command is triggered,
  /// the observations that belong to it will be executed synchronously in the
  /// order they were added.
  ///
  /// You can pass the returned ``Observation`` instance into the ``removeObservation(_:)``
  /// method or similar to remove the observation and stop the execution of its handler.
  @discardableResult
  public func observe(_ eventType: EventType, handler: @escaping () -> Void) -> Observation {
    let observation = Observation(eventType, handler: handler)
    addObservation(observation)
    return observation
  }

  /// Removes the given observation.
  ///
  /// Pass an instance of ``Observation`` that you received from a call to
  /// ``observe(_:handler:)``. The observation must belong to this command.
  /// Once the observation has been removed, its handler will no longer be executed.
  public func removeObservation(_ observation: Observation) {
    proxy.keyCommandObservations.removeAll { $0 == observation }
  }

  /// Removes the given observations.
  ///
  /// Pass instances of ``Observation`` that you received from calls to
  /// ``observe(_:handler:)``. The observation must belong to this command.
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
  /// let command = KeyCommand(name: someName)
  /// command.removeFirstObservation(where: { $0.eventType == .keyDown })
  /// ```
  ///
  /// Only observations belonging to this key command will be considered for
  /// removal. Once the observation has been removed, its handler will no
  /// longer be executed.
  public func removeFirstObservation(where shouldRemove: (Observation) throws -> Bool) rethrows {
    if let index = try proxy.keyCommandObservations.firstIndex(where: shouldRemove) {
      proxy.keyCommandObservations.remove(at: index)
    }
  }

  /// Removes every observation that matches the given predicate.
  ///
  /// Use this method if you need to remove multiple ``Observation`` instances
  /// that you don't have access to. This example removes all observations for
  /// the ``EventType/keyDown`` event type:
  ///
  /// ```swift
  /// let command = KeyCommand(name: someName)
  /// command.removeObservations(where: { $0.eventType == .keyDown })
  /// ```
  ///
  /// Only observations belonging to this key command will be considered for
  /// removal. Once the observation has been removed, its handler will no
  /// longer be executed.
  public func removeObservations(where shouldRemove: (Observation) throws -> Bool) rethrows {
    try proxy.keyCommandObservations.removeAll(where: shouldRemove)
  }

  /// Removes all observations from the key command.
  ///
  /// Once the observations have been removed, their handlers will no
  /// longer be executed.
  public func removeAllObservations() {
    proxy.keyCommandObservations.removeAll()
  }

  /// Enables the key command.
  ///
  /// When enabled, the command's observation handlers become active, and will
  /// be executed whenever it is triggered. Note that calling ``observe(_:handler:)``
  /// automatically enables the command.
  public func enable() {
    proxy.register()
  }

  /// Disables the key command.
  ///
  /// When disabled, the command's observation handlers become dormant, but are
  /// retained, so that it can be re-enabled later. If you wish to completely
  /// remove the command and its handlers, use the ``remove()`` method instead.
  public func disable() {
    proxy.unregister()
  }

  /// Completely removes the key command and its handlers.
  ///
  /// Once this method has been called, the command should be considered invalid.
  /// The ``enable()`` method will have no effect. If you wish to re-enable it,
  /// you will need to call ``observe(_:handler:)`` and provide a new handler.
  public func remove() {
    proxy.unregister()
    ProxyStorage.remove(proxy)
  }

  /// Runs the key command's observation handlers for the given event type.
  ///
  /// ```swift
  /// let command = KeyCommand(
  ///     name: "SomeName",
  ///     key: .space,
  ///     modifiers: [.shift, .command]
  /// )
  ///
  /// command.observe(.keyDown) {
  ///     print("'Shift + Command + Space' was pressed.")
  /// }
  /// command.observe(.keyUp) {
  ///     print("'Shift + Command + Space' was released.")
  /// }
  /// command.observe(.doubleTap(0.5)) {
  ///     print("'Shift + Command + Space' was pressed twice within 0.5 seconds.")
  /// }
  ///
  /// command.runHandlers(for: .keyDown)
  /// // Prints: 'Shift + Command + Space' was pressed.
  ///
  /// command.runHandlers(for: .keyUp)
  /// // Prints: 'Shift + Command + Space' was released.
  ///
  /// command.runHandlers(for: .doubleTap(0.5))
  /// // Prints: 'Shift + Command + Space' was pressed twice within 0.5 seconds.
  /// ```
  public func runHandlers(for eventType: EventType) {
    proxy.performObservations(matching: eventType)
  }

  /// Runs the key command's observation handlers that match the given predicate.
  ///
  /// ```swift
  /// let command = KeyCommand(
  ///     name: "SomeName",
  ///     key: .space,
  ///     modifiers: [.shift, .command]
  /// )
  ///
  /// command.observe(.keyDown) {
  ///     print("'Shift + Command + Space' was pressed.")
  /// }
  /// command.observe(.keyUp) {
  ///     print("'Shift + Command + Space' was released.")
  /// }
  ///
  /// command.runHandlers {
  ///     $0.eventType == .keyDown || $0.eventType == .keyUp
  /// }
  ///
  /// // Prints:
  /// // 'Shift + Command + Space' was pressed.
  /// // 'Shift + Command + Space' was released.
  /// ```
  public func runHandlers(where predicate: (Observation) throws -> Bool) rethrows {
    for observation in proxy.keyCommandObservations where try predicate(observation) {
      observation.perform()
    }
  }
}

// MARK: - EventType

extension KeyCommand {
  /// Constants that specify the event type of a key command.
  ///
  /// Pass one of these constants into a key command's ``observe(_:handler:)``
  /// method. The closure you provide in that method will be called whenever
  /// a command matching the constant is triggered.
  ///
  /// ```swift
  /// let command = KeyCommand(
  ///     name: "SomeName",
  ///     key: .leftArrow,
  ///     modifiers: [.command, .option]
  /// )
  ///
  /// command.observe(.keyDown) {
  ///     print("KEY DOWN")
  /// }
  ///
  /// command.observe(.keyUp) {
  ///     print("KEY UP")
  /// }
  ///
  /// command.observe(.doubleTap(0.5)) {
  ///     print("DOUBLE TAP")
  /// }
  /// ```
  ///
  /// - Tip: You can call ``observe(_:handler:)`` as many times as you want.
  public enum EventType {
    /// Indicates that the key is in the "up" position.
    case keyUp

    /// Indicates that the key is in the "down" position.
    case keyDown

    /// Indicates that the key was pressed twice within the given time interval.
    case doubleTap(_ interval: TimeInterval)

    init?(_ eventKind: Int) {
      switch eventKind {
      case kEventHotKeyPressed, kEventRawKeyDown:
        self = .keyDown
      case kEventHotKeyReleased, kEventRawKeyUp:
        self = .keyUp
      default:
        return nil
      }
    }

    init?(_ eventRef: EventRef) {
      self.init(Int(GetEventKind(eventRef)))
    }
  }
}

// MARK: - Protocol conformances

extension KeyCommand: Codable { }

extension KeyCommand: CustomStringConvertible {
  public var description: String {
    var keyString = "nil"
    if let key {
      keyString = "\(key)"
    }
    return "\(Self.self)("
    + "name: \(name), "
    + "key: \(keyString), "
    + "modifiers: \(modifiers))"
  }
}

extension KeyCommand: Equatable { }

extension KeyCommand: Hashable { }

extension KeyCommand.EventType: Codable { }

extension KeyCommand.EventType: Equatable { }

extension KeyCommand.EventType: Hashable { }
