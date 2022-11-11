//===----------------------------------------------------------------------===//
//
// NSMenuItemExt.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit

private var storage = [ObjectIdentifier: [String: Any]]()

extension NSMenuItem {
  
  // MARK: - Nested Types
  
  struct Storage<T> {
    private let key: String
    private let object: AnyObject
    private var value: T?
    
    init(object: AnyObject, key: String = #function) {
      self.key = key
      self.object = object
    }
    
    func get() -> T? {
      guard let objectStorage = storage[.init(object)] else {
        return nil
      }
      return objectStorage[key] as? T
    }
    
    func get(backup: T) -> T {
      get() ?? backup
    }
    
    func set(_ value: T) {
      guard var objectStorage = storage[.init(object)] else {
        storage[.init(object)] = [key: value]
        return
      }
      objectStorage[key] = value
      storage[.init(object)] = objectStorage
    }
  }
  
  // MARK: - Properties
  
  // The custom action that the user provides.
  var handler: (() -> Void)? {
    get { Storage(object: self).get() }
    set { Storage(object: self).set(newValue) }
  }
  
  // Use this to retrieve the key command.
  var name: KeyCommand.Name? {
    get { Storage(object: self).get() }
    set { Storage(object: self).set(newValue) }
  }
  
  // We need to observe the key command and proxy for changes in their
  // state, so that we can update the menu item to match. We store
  // all the observations here.
  var observations: Set<AnyHashable> {
    get { Storage(object: self).get(backup: []) }
    set { Storage(object: self).set(newValue) }
  }
  
  // If there was no original action, we don't want to keep trying to
  // set it, so we flip this as soon as an attempt is made, regardless
  // of whether anything was actually set.
  var originalActionHasBeenSet: Bool {
    get { Storage(object: self).get(backup: false) }
    set { Storage(object: self).set(newValue) }
  }
  
  // See above
  var originalKeyEquivalentHasBeenSet: Bool {
    get { Storage(object: self).get(backup: false) }
    set { Storage(object: self).set(newValue) }
  }
  
  // See above
  var originalModifierMaskHasBeenSet: Bool {
    get { Storage(object: self).get(backup: false) }
    set { Storage(object: self).set(newValue) }
  }
  
  // We need to save the original action so that it can still be performed
  // once we change the action to our own.
  var originalAction: Selector? {
    get { Storage(object: self).get() }
    set {
      if !originalActionHasBeenSet {
        Storage(object: self).set(newValue)
      }
      originalActionHasBeenSet = true
    }
  }
  
  // We need to save the original key equivalent so that we can restore
  // it if the user removes the key command from the menu.
  var originalKeyEquivalent: String {
    get { Storage(object: self).get(backup: "") }
    set {
      if !originalKeyEquivalentHasBeenSet {
        Storage(object: self).set(newValue)
      }
      originalKeyEquivalentHasBeenSet = true
    }
  }
  
  // See above
  var originalModifierMask: NSEvent.ModifierFlags {
    get { Storage(object: self).get(backup: []) }
    set {
      if !originalModifierMaskHasBeenSet {
        Storage(object: self).set(newValue)
      }
      originalModifierMaskHasBeenSet = true
    }
  }
  
  /// A key command associated with the menu item.
  ///
  /// When this value is set, the menu item's key equivalent and modifier mask
  /// are set to match with the command. You can then observe the command
  /// using its ``KeyCommand/observe(_:handler:)`` method. The handler you provide,
  /// as well as the menu item's action will be executed both when the key
  /// combination is pressed (or released), and when the menu item is clicked.
  public var command: KeyCommand? {
    get {
      guard let name = name else {
        return nil
      }
      return .init(name: name)
    }
    set {
      name = newValue?.name
      registerKeyCommand()
    }
  }
  
  @available(*, deprecated, renamed: "command")
  public var keyEvent: KeyEvent? {
    get { command }
    set { command = newValue }
  }
  
  // MARK: - Public Methods
  
  /// Sets the value of the menu item's `command` property, while allowing
  /// you to provide an additional change handler that will execute immediately
  /// after the menu item's action has been performed.
  ///
  /// If you don't need to provide a change handler, you can simply set the
  /// value of the menu item's `command` property instead.
  public func setKeyCommand(_ command: KeyCommand, handler: @escaping () -> Void) {
    self.handler = handler
    self.command = command
  }
  
  @available(*, deprecated, renamed: "setKeyCommand(_:handler:)")
  public func setKeyEvent(_ keyEvent: KeyEvent, handler: @escaping () -> Void) {
    setKeyCommand(keyEvent, handler: handler)
  }
  
  /// Removes and disables the menu item's key command.
  ///
  /// - Parameter disabling: A Boolean value that determines whether the key
  ///   command should be disabled when it is removed from the menu item. If
  ///   false, the menu item will remove its key equivalent and modifier mask,
  ///   but the command will remain active.
  public func removeKeyCommand(disabling: Bool = true) {
    resetKeyEquivalentAndMask()
    if disabling {
      command?.disable()
    }
    name = nil
    handler = nil
  }
  
  @available(*, deprecated, renamed: "removeKeyCommand(disabling:)")
  public func removeKeyEvent(disabling: Bool = true) {
    removeKeyCommand(disabling: disabling)
  }
  
  // MARK: - Internal Methods
  
  @objc
  func performCombinedAction(_ sender: Any) {
    if let action = originalAction {
      NSApp.perform(action, with: sender)
    }
    guard
      let command = command,
      command.isEnabled
    else {
      return
    }
    handler?()
  }
  
  func setKeyEquivalent() {
    originalKeyEquivalent = keyEquivalent
    originalModifierMask = keyEquivalentModifierMask
    guard let command = command else {
      resetKeyEquivalentAndMask()
      return
    }
    keyEquivalent = command.key?.stringValue ?? keyEquivalent
    keyEquivalentModifierMask = command.modifiers.cocoaFlags
  }
  
  func resetKeyEquivalentAndMask() {
    keyEquivalent = originalKeyEquivalent
    keyEquivalentModifierMask = originalModifierMask
  }
  
  func removeObservations<H: Hashable>(ofType type: H.Type) {
    if H.self is KeyCommand.Observation.Type {
      for observation in observations {
        if let base = observation.base as? KeyCommand.Observation {
          command?.removeObservation(base)
          observations.remove(observation)
        }
      }
    } else if H.self is VoidHandler.Type {
      for observation in observations {
        if let base = observation.base as? VoidHandler {
          command?.proxy.removeHandler(base)
          observations.remove(observation)
        }
      }
    }
  }
  
  func registerKeyCommand() {
    originalAction = action
    
    removeObservations(ofType: KeyCommand.Observation.self)
    removeObservations(ofType: VoidHandler.self)
    
    guard let command = command else {
      resetKeyEquivalentAndMask()
      return
    }
    
    setKeyEquivalent()
    
    action = #selector(performCombinedAction(_:))
    target = self
    
    observations.update(
      with: .init(
        command.observe(.keyDown) { [weak self] in
          guard let self = self else {
            return
          }
          self.performCombinedAction(self)
        }
      )
    )
    
    observations.update(
      with: .init(
        command.proxy.observeKeyAndModifierChanges {
          self.setKeyCommand(command, handler: self.handler ?? { })
        }
      )
    )
    
    observations.update(
      with: .init(
        command.proxy.observeRegistrationState {
          if command.isEnabled {
            self.setKeyEquivalent()
          } else {
            self.resetKeyEquivalentAndMask()
          }
        }
      )
    )
  }
}
