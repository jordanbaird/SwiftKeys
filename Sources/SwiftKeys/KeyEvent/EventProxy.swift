//===----------------------------------------------------------------------===//
//
// EventProxy.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox

final class EventProxy {
  typealias EventType = KeyEvent.EventType
  
  struct Observation: IdentifiableObservation {
    let id = rng.next()
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
  private static let signature = OSType.random(in: (.min)...(.max))
  
  static var isInstalled: Bool {
    eventHandlerRef != nil
  }
  
  var hotKeyRef: EventHotKeyRef?
  let identifier = EventHotKeyID(signature: signature, id: proxyCount)
  
  let name: KeyEvent.Name
  var eventObservations = [KeyEvent.Observation]()
  
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
      // If already registered, we need to re-register
      // for the new key.
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
      // If already registered, we need to re-register
      // for the new modifiers.
      if isRegistered {
        register()
      }
      for observation in keyAndModifierChangeObservations {
        observation.perform()
      }
    }
  }
  
  var objectIdentifier: ObjectIdentifier {
    .init(self)
  }
  
  init(name: KeyEvent.Name) {
    self.name = name
    Self.proxyCount += 1
  }
  
  func install() -> OSStatus {
    guard !Self.isInstalled else {
      return noErr
    }
    
    let handler: EventHandlerUPP = { callRef, event, userData in
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
      
      // Make sure the event is one of ours (a.k.a. if its signature
      // lines up with our signature), and that we have a stored proxy
      // for the event.
      guard
        identifier.signature == EventProxy.signature,
        let proxy = ProxyStorage.proxy(with: identifier.id)
      else {
        return OSStatus(eventNotHandledErr)
      }
      
      // Execute the proxy's stored handlers.
      proxy.performObservations(matching: EventType(event))
      
      return noErr
    }
    
    return InstallEventHandler(
      GetEventDispatcherTarget(),
      handler,
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
      unregister(shouldReregister: true)
      return
    }
    
    // Always try to install. The first thing the install() method
    // does is check whether we're already installed, so this will
    // be quick. Note that if we're already installed, the install()
    // method returns noErr.
    var status = install()
    
    guard status == noErr else {
      EventError.installationFailed(code: status).log()
      return
    }
    
    status = RegisterEventHotKey(
      key.unsigned,
      modifiers.carbonFlags,
      identifier,
      GetEventDispatcherTarget(),
      0,
      &hotKeyRef)
    
    // We need to retain a reference to each proxy instance. The C
    // function inside of the `install()` method can't deal with
    // context, so we can't inject or reference `self`. We _do_ have
    // a way to access the proxy's identifier, so we can use that
    // to store the proxy, then access the storage from inside the
    // C function.
    ProxyStorage.store(self)
    
    guard status == noErr else {
      EventError.registrationFailed(code: status).log()
      return
    }
    
    do {
      let data = try JSONEncoder().encode(KeyEvent(name: name))
      UserDefaults.standard.set(data, forKey: name.combinedValue)
    } catch {
      // Rather than return, just log the error. Everything else
      // worked properly, the event just wasn't stored. All things
      // considered, a relatively minor error, but one that the
      // programmer should be made aware of nonetheless.
      EventError.encodingFailed(code: OSStatus(eventInternalErr)).log()
    }
    
    isRegistered = true
  }
  
  func unregister(shouldReregister: Bool = false) {
    guard
      !blockRegistrationChanges,
      isRegistered
    else {
      return
    }
    let status = UnregisterEventHotKey(hotKeyRef)
    hotKeyRef = nil
    if status != noErr {
      EventError.unregistrationFailed(code: status).log()
    }
    UserDefaults.standard.removeObject(forKey: name.combinedValue)
    isRegistered = false
    if shouldReregister {
      register()
    }
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
  
  func performObservations(matching eventType: EventType?) {
    eventObservations.performObservations(matching: eventType)
  }
  
  deinit {
    unregister()
  }
}

extension EventProxy: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(objectIdentifier)
  }
}

extension EventProxy: Equatable {
  static func == (lhs: EventProxy, rhs: EventProxy) -> Bool {
    lhs.objectIdentifier == rhs.objectIdentifier
  }
}

// MARK: - ProxyStorage

typealias ProxyStorage = Set<EventProxy>

extension Set where Element == EventProxy {
  private static var all = Self()
  
  static func proxy(with identifier: UInt32) -> EventProxy? {
    all.first { $0.identifier.id == identifier }
  }
  
  static func proxy(with name: KeyEvent.Name) -> EventProxy? {
    all.first { $0.name == name }
  }
  
  static func store(_ proxy: EventProxy) {
    all.update(with: proxy)
  }
  
  static func remove(_ proxy: EventProxy) {
    all.remove(proxy)
  }
}
