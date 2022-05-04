//===----------------------------------------------------------------------===//
//
// EventProxy.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox

final class EventProxy {
  struct Observation: IdentifiableObservation {
    let id = idGenerator.next()
    let value: () -> Void
  }
  
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
  var observations = [KeyEvent.Observation]()
  
  var keyAndModifierChangeObservations = Set<Observation>()
  var registrationStateObservations = Set<Observation>()
  
  var blockRegistrationChanges = false
  
  var isRegistered = false {
    didSet {
      for observation in registrationStateObservations {
        observation.perform()
      }
    }
  }
  
  var key: KeyEvent.Key? = nil {
    didSet {
      // Re-register if necessary.
      if isRegistered {
        register()
      }
      for observation in keyAndModifierChangeObservations {
        observation.perform()
      }
    }
  }
  
  var modifiers = [KeyEvent.Modifier]() {
    didSet {
      // Re-register if necessary.
      if isRegistered {
        register()
      }
      for observation in keyAndModifierChangeObservations {
        observation.perform()
      }
    }
  }
  
  init(name: KeyEvent.Name) {
    self.name = name
    Self.proxyCount += 1
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
          let proxy = ProxyStorage.proxy(with: identifier.id)
        else {
          return OSStatus(eventNotHandledErr)
        }
        
        // Execute the proxy's stored handlers.
        for observation in proxy.observations {
          observation.tryToPerform(with: event)
        }
        
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
    // inject or reference `self`. We _do_ have a way to access the proxy's
    // identifier, so we can use that to store the proxy, then access the
    // storage from inside the C function.
    ProxyStorage.store(self)
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
    hotKeyRef = nil
    if status != noErr {
      logError(.unregistrationFailed(code: status))
    }
    UserDefaults.standard.removeObject(forKey: name.combinedValue)
    isRegistered = false
  }
  
  @discardableResult
  func observeKeyAndModifierChanges(_ handler: @escaping () -> Void) -> Observation {
    let observation = Observation(value: handler)
    keyAndModifierChangeObservations.update(with: observation)
    return observation
  }
  
  @discardableResult
  func removeObservation(_ observation: Observation) -> Observation? {
    keyAndModifierChangeObservations.remove(observation) ??
    registrationStateObservations.remove(observation)
  }
  
  @discardableResult
  func observeRegistrationState(_ handler: @escaping () -> Void) -> Observation {
    let observation = Observation(value: handler)
    registrationStateObservations.update(with: observation)
    return observation
  }
  
  func mutateWithoutChangingRegistrationState(_ handler: (EventProxy) throws -> Void) rethrows {
    blockRegistrationChanges = true
    defer {
      blockRegistrationChanges = false
    }
    try handler(self)
  }
  
  deinit {
    unregister()
  }
}

// MARK: - ProxyStorage

struct ProxyStorage: Hashable {
  private static var all = Set<Self>()
  
  private let proxy: EventProxy
  
  private init(_ proxy: EventProxy) {
    self.proxy = proxy
  }
  
  static func proxy(with identifier: UInt32) -> EventProxy? {
    all.first { $0.proxy.identifier.id == identifier }?.proxy
  }
  
  static func proxy(with name: KeyEvent.Name) -> EventProxy? {
    all.first { $0.proxy.name == name }?.proxy
  }
  
  static func store(_ proxy: EventProxy) {
    all.update(with: .init(proxy))
  }
  
  static func remove(_ proxy: EventProxy) {
    if let storage = all.first(where: { $0 ~= proxy }) {
      all.remove(storage)
    }
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(proxy.identifier.id)
    hasher.combine(proxy.name)
  }
  
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.proxy.identifier.id == rhs.proxy.identifier.id &&
    lhs.proxy.name == rhs.proxy.name
  }
  
  static func ~= (lhs: Self, rhs: EventProxy) -> Bool {
    lhs.proxy.identifier.id == rhs.identifier.id &&
    lhs.proxy.name == rhs.name
  }
}
