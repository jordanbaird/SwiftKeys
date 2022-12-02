//===----------------------------------------------------------------------===//
//
// NSMenuItemExt.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit

extension NSMenuItem {
  private static let keyCommandNameStorage = Storage<KeyCommand.Name>()
  private static let keyAndModifierChangeHandlerStorage = Storage<VoidHandler>()
  private static let observationStorage = Storage<Set<NSKeyValueObservation>>()

  private var keyAndModifierChangeHandler: VoidHandler? {
    get { Self.keyAndModifierChangeHandlerStorage[self] }
    set { Self.keyAndModifierChangeHandlerStorage[self] = newValue }
  }

  private var observations: Set<NSKeyValueObservation> {
    get { Self.observationStorage[self] ?? [] }
    set { Self.observationStorage[self] = newValue }
  }

  /// A key command associated with the menu item.
  ///
  /// When this value is set, the menu item's key equivalent and
  /// modifier mask are updated to match those of the command.
  /// Likewise, when either the menu item's key equivalent, or its
  /// modifier mask is set, the key command updates to the new value.
  ///
  /// - Important: If you set this property, you need to manually
  ///   disable the command before the menu opens, otherwise the
  ///   menu will block the command's handlers from running until
  ///   it closes.
  public var command: KeyCommand? {
    get {
      guard let name = Self.keyCommandNameStorage[self] else {
        return nil
      }
      return .init(name: name)
    }
    set {
      observations.removeAll()
      if let handler = keyAndModifierChangeHandler {
        command?.proxy.removeHandler(handler)
      }

      Self.keyCommandNameStorage[self] = newValue?.name

      let handler = VoidHandler { [weak self] in
        self?.setKeyEquivalentAndModifierMask()
      }
      keyAndModifierChangeHandler = handler
      newValue?.proxy.keyAndModifierChangeHandlers.insert(handler)

      handler.perform()

      observations = [
        observe(\.keyEquivalent, options: [.old, .new]) { [weak self] _, changes in
          guard
            let self,
            let oldValue = changes.oldValue,
            let newValue = changes.newValue,
            oldValue != newValue,
            var command = self.command,
            let key = KeyCommand.Key(keyEquivalent: newValue)
          else {
            return
          }
          command.key = key
          self.command = command
        },
        observe(\.keyEquivalentModifierMask, options: [.old, .new]) { [weak self] _, changes in
          guard
            let self,
            let oldValue = changes.oldValue,
            let newValue = changes.newValue,
            oldValue != newValue,
            var command = self.command
          else {
            return
          }
          command.modifiers = newValue.swiftKeysModifiers
          self.command = command
        },
      ]
    }
  }

  private func setKeyEquivalentAndModifierMask() {
    keyEquivalent = command?.key?.keyEquivalent ?? ""
    keyEquivalentModifierMask = command?.modifiers.cocoaFlags ?? []
  }
}
