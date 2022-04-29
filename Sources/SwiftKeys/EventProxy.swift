//===----------------------------------------------------------------------===//
//
// EventProxy.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox

final class EventProxy {
  static var all = [UInt32: EventProxy]()
  
  private static var eventHandlerRef: EventHandlerRef?
  private static let eventTypes = [
    EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed)),
    EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyReleased)),
  ]
  
  private static var proxyCount: UInt32 = 0
  private static let signature = OSType.random(in: OSType.min...OSType.max)
  
  static var isInstalled: Bool {
    eventHandlerRef != nil
  }
  
  var hotKeyRef: EventHotKeyRef?
  let identifier = EventHotKeyID(signature: signature, id: proxyCount)
  
  let name: KeyEvent.Name
  var observations = [(type: EventType, handler: () -> Void)]()
  
  var blockRegistrationChanges = false
  
  var registrationStateHandlers = [() -> Void]()
  var isRegistered = false {
    didSet {
      for handler in registrationStateHandlers {
        handler()
      }
    }
  }
  
  var key: KeyEvent.Key? = nil {
    didSet {
      // Re-register if necessary.
      if isRegistered {
        register()
      }
    }
  }
  
  var modifiers = [KeyEvent.Modifier]() {
    didSet {
      // Re-register if necessary.
      if isRegistered {
        register()
      }
    }
  }
  
  init(name: KeyEvent.Name) {
    self.name = name
    Self.proxyCount += 1
  }
  
  private func executeHandlers(for ref: EventRef) {
    let type = EventType(ref)
    for observation in observations where observation.type == type {
      observation.handler()
    }
  }
  
  func install() -> OSStatus {
    guard !Self.isInstalled else {
      return noErr
    }
    
    return InstallEventHandler(
      GetEventDispatcherTarget(),
      { callRef, event, userData in
        guard let event = event else {
          return OSStatus(eventNotHandledErr)
        }
        
        // Create an identifier from the event.
        var identifier = EventHotKeyID()
        let status = GetEventParameter(
          event,
          EventParamName(kEventParamDirectObject),
          EventParamType(typeEventHotKeyID),
          nil,
          MemoryLayout<EventHotKeyID>.size,
          nil,
          &identifier)
        
        // Make sure the creation was successful.
        guard status == noErr else {
          return status
        }
        
        // Make sure the event is one of ours (a.k.a. if its signature lines up
        // with our signature), and that we have a stored proxy for the event.
        guard
          identifier.signature == EventProxy.signature,
          let proxy = EventProxy.all[identifier.id]
        else {
          return OSStatus(eventNotHandledErr)
        }
        
        // Execute the proxy's stored handlers.
        proxy.executeHandlers(for: event)
        
        return noErr
      },
      Self.eventTypes.count,
      Self.eventTypes,
      nil,
      &Self.eventHandlerRef)
  }
  
  func register() {
    guard
      !blockRegistrationChanges,
      !modifiers.isEmpty,
      let key = key
    else {
      return
    }
    guard !isRegistered else {
      // This method might have been called because the key or
      // modifiers have changed, and need to be re-registered.
      unregister()
      return register()
    }
    
    // Always try to install. The first thing that happens in that method
    // is to check whether we're already installed, so this will be quick.
    // Note that if we're already installed, the method returns `noErr`,
    // so we don't have to worry about accidental console logs.
    var status = install()
    if status != noErr {
      logError(.installationFailed(code: status))
      return
    }
    status = RegisterEventHotKey(
      key.unsigned,
      modifiers.carbonFlags,
      identifier,
      GetEventDispatcherTarget(),
      0,
      &hotKeyRef)
    
    // We need to retain a reference to each proxy instance. The C function
    // inside of the `install()` method can't deal with objects, so we can't
    // inject or reference `self`. We _do_ have a way to access the event's
    // identifier, so we can use that to store the proxy, then access the
    // storage from inside the C function.
    Self.all[identifier.id] = self
    if status != noErr {
      logError(.registrationFailed(code: status))
    }
    
    do {
      let data = try JSONEncoder().encode(KeyEvent(name: name))
      UserDefaults.standard.set(data, forKey: name.combinedValue)
    } catch {
      logError(.encodingFailed(code: OSStatus(eventInternalErr)))
    }
    
    isRegistered = true
  }
  
  func unregister() {
    guard
      !blockRegistrationChanges,
      isRegistered
    else {
      return
    }
    let status = UnregisterEventHotKey(hotKeyRef)
    Self.all.removeValue(forKey: identifier.id)
    hotKeyRef = nil
    if status != noErr {
      logError(.unregistrationFailed(code: status))
    }
    UserDefaults.standard.removeObject(forKey: name.combinedValue)
    isRegistered = false
  }
  
  func observeRegistrationState(_ handler: @escaping () -> Void) {
    registrationStateHandlers.append(handler)
  }
  
  func mutateWithoutChangingRegistrationState(_ handler: (EventProxy) throws -> Void) rethrows {
    blockRegistrationChanges = true
    try handler(self)
    blockRegistrationChanges = false
  }
  
  deinit {
    unregister()
  }
}
