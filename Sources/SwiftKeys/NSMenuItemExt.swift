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
  
  // Use this to retrieve the key event.
  var name: KeyEvent.Name? {
    get { Storage(object: self).get() }
    set { Storage(object: self).set(newValue) }
  }
  
  // We need to observe the key event and proxy for changes in their
  // state, so that we can update the menu item to match. We store
  // all the observations here.
  var observations: Set<AnyIdentifiableObservation> {
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
  // it if the user removes the key event from the menu.
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
  
  /// A key event associated with the menu item.
  ///
  /// When this value is set, the menu item's key equivalent and modifier mask
  /// are set to match with the key event. You can then observe the key event
  /// using its ``KeyEvent/observe(_:handler:)`` method. The handler you provide,
  /// as well as the menu item's action will be executed both when the key
  /// combination is pressed (or released), and when the menu item is clicked.
  public var keyEvent: KeyEvent? {
    get {
      guard let name = name else { return nil }
      return .init(name: name)
    }
    set {
      name = newValue?.name
      registerKeyEvent()
    }
  }
  
  // MARK: - Public Methods
  
  /// Sets the value of the menu item's `keyEvent` property, while allowing
  /// you to provide an additional change handler that will execute immediately
  /// after the menu item's action has been performed.
  ///
  /// If you don't need to provide a change handler, you can simply set the
  /// value of the menu item's `keyEvent` property instead.
  public func setKeyEvent(_ keyEvent: KeyEvent, handler: @escaping () -> Void) {
    self.handler = handler
    self.keyEvent = keyEvent
  }
  
  /// Removes and disables the menu item's key event.
  ///
  /// - Parameter disabling: A Boolean value that determines whether the key event
  /// should be disabled when it is removed from the menu item. If false, the menu
  /// item will remove its key equivalent and modifier mask, but the event will
  /// remain active.
  public func removeKeyEvent(disabling: Bool = true) {
    resetKeyEquivalentAndMask()
    if disabling {
      keyEvent?.disable()
    }
    name = nil
    handler = nil
  }
  
  // MARK: - Internal Methods
  
  @objc
  func performCombinedAction(_ sender: Any) {
    if let action = originalAction {
      NSApp.perform(action, with: sender)
    }
    guard
      let keyEvent = keyEvent,
      keyEvent.isEnabled
    else {
      return
    }
    handler?()
  }
  
  func setKeyEquivalent() {
    originalKeyEquivalent = keyEquivalent
    originalModifierMask = keyEquivalentModifierMask
    guard let keyEvent = keyEvent else {
      resetKeyEquivalentAndMask()
      return
    }
    keyEquivalent = keyEvent.key?.stringValue ?? keyEquivalent
    keyEquivalentModifierMask = keyEvent.modifiers.cocoaFlags
  }
  
  func resetKeyEquivalentAndMask() {
    keyEquivalent = originalKeyEquivalent
    keyEquivalentModifierMask = originalModifierMask
  }
  
  func removeObservations<T: IdentifiableObservation>(ofType type: T.Type) {
    if T.self is KeyEvent.Observation.Type {
      for observation in observations {
        if let base = observation.base as? KeyEvent.Observation {
          keyEvent?.removeObservation(base)
          observations.remove(observation)
        }
      }
    } else if T.self is EventProxy.Observation.Type {
      for observation in observations {
        if let base = observation.base as? EventProxy.Observation {
          keyEvent?.proxy.removeObservation(base)
          observations.remove(observation)
        }
      }
    }
  }
  
  func registerKeyEvent() {
    originalAction = action
    
    removeObservations(ofType: KeyEvent.Observation.self)
    removeObservations(ofType: EventProxy.Observation.self)
    
    guard let keyEvent = keyEvent else {
      resetKeyEquivalentAndMask()
      return
    }
    
    setKeyEquivalent()
    
    action = #selector(performCombinedAction(_:))
    target = self
    
    observations.update(
      with: .init(
        keyEvent.observe(.keyDown) { [weak self] in
          guard let self = self else { return }
          self.performCombinedAction(self)
        }
      )
    )
    
    observations.update(
      with: .init(
        keyEvent.proxy.observeKeyAndModifierChanges {
          self.setKeyEvent(keyEvent, handler: self.handler ?? { })
        }
      )
    )
    
    observations.update(
      with: .init(
        keyEvent.proxy.observeRegistrationState {
          if keyEvent.isEnabled {
            self.setKeyEquivalent()
          } else {
            self.resetKeyEquivalentAndMask()
          }
        }
      )
    )
  }
}
