//===----------------------------------------------------------------------===//
//
// Proxy.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox

final class Proxy {
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
  private static let signature = OSType.random(in: OSType.min...OSType.max)
  
  static var isInstalled: Bool {
    eventHandlerRef != nil
  }
  
  var hotKeyRef: EventHotKeyRef?
  let identifier = EventHotKeyID(signature: signature, id: proxyCount)
  
  let name: KeyCommand.Name
  var keyCommandObservations = [KeyCommand.Observation]()
  
  var keyAndModifierChangeObservations = Set<Observation>()
  var registrationStateObservations = Set<Observation>()
  
  var blockRegistrationChanges = false
  
  var lastKeyDownDate = Date()
  
  var isRegistered = false {
    didSet {
      for observation in registrationStateObservations {
        observation.perform()
      }
    }
  }
  
  var key: KeyCommand.Key? = nil {
    didSet {
      // If already registered, we need to re-register
      // for the new key.
      if isRegistered {
        unregister(shouldReregister: true)
      }
      for observation in keyAndModifierChangeObservations {
        observation.perform()
      }
    }
  }
  
  var modifiers = [KeyCommand.Modifier]() {
    didSet {
      // If already registered, we need to re-register
      // for the new modifiers.
      if isRegistered {
        unregister(shouldReregister: true)
      }
      for observation in keyAndModifierChangeObservations {
        observation.perform()
      }
    }
  }
  
  var objectIdentifier: ObjectIdentifier {
    .init(self)
  }
  
  init(with name: KeyCommand.Name, storing shouldStore: Bool = false) {
    self.name = name
    Self.proxyCount += 1
    if shouldStore {
      ProxyStorage.store(self)
    }
  }
  
  static func install() -> OSStatus {
    guard !isInstalled else {
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
        identifier.signature == Proxy.signature,
        let proxy = ProxyStorage.proxy(with: identifier.id)
      else {
        return OSStatus(eventNotHandledErr)
      }
      
      var eventTypes = [KeyCommand.EventType(event)]
      
      if eventTypes == [.keyDown] {
        let currentDate = Date()
        eventTypes.append(.doubleTap(currentDate.timeIntervalSince(proxy.lastKeyDownDate)))
        proxy.lastKeyDownDate = currentDate
      }
      
      // Execute the proxy's stored handlers.
      for eventType in eventTypes {
        proxy.performObservations {
          switch $0 {
          case .doubleTap(let requiredInterval):
            switch eventType {
            case .doubleTap(let realInterval):
              // The real interval of the observation must be within the bounds
              // of the required interval. Example:
              //
              // command.observe(.doubleTap(1)) { ... }
              //
              // The above observation requires that, in order for its handler
              // to be executed, the time between key presses must be less than
              // or equal to 1 second.
              return realInterval <= requiredInterval
            default:
              return false
            }
          default:
            return $0 == eventType
          }
        }
      }
      
      return noErr
    }
    
    return InstallEventHandler(
      GetEventDispatcherTarget(),
      handler,
      eventTypes.count,
      eventTypes,
      nil,
      &eventHandlerRef)
  }
  
  static func uninstall() throws {
    guard isInstalled else {
      return
    }
    let status = RemoveEventHandler(eventHandlerRef)
    guard status == noErr else {
      throw KeyCommandError.uninstallationFailed(status: status)
    }
    eventHandlerRef = nil
  }
  
  func register() {
    guard
      !blockRegistrationChanges,
      !modifiers.isEmpty,
      let key = key
    else {
      return
    }
    
    if isRegistered {
      // If already registered, we need to unregister first,
      // or we'll end up with two conflicting registrations.
      unregister()
    }
    
    // Always try to install. The first thing the install() method
    // does is check whether we're already installed, so this will
    // be quick. Note that if we're already installed, the install()
    // method returns noErr.
    var status = Self.install()
    
    guard status == noErr else {
      KeyCommandError.installationFailed(status: status).log()
      return
    }
    
    status = RegisterEventHotKey(
      key.unsigned,
      modifiers.carbonFlags,
      identifier,
      GetEventDispatcherTarget(),
      0,
      &hotKeyRef)
    
    guard status == noErr else {
      KeyCommandError.registrationFailed(status: status).log()
      return
    }
    
    // We need to retain a reference to each proxy instance. The C
    // function inside of the `install()` method can't deal with
    // context, so we can't inject or reference `self`. We _do_ have
    // a way to access the proxy's identifier, so we can use that
    // to store the proxy, then access the storage from inside the
    // C function.
    ProxyStorage.store(self)
    
    do {
      let data = try JSONEncoder().encode(KeyCommand(name: name))
      UserDefaults.standard.set(data, forKey: name.combinedValue)
    } catch {
      // Rather than return, just log the error. Everything else
      // worked properly, the command just wasn't stored. All things
      // considered, a relatively minor error, but one that the
      // programmer should be made aware of nonetheless.
      KeyCommandError.encodingFailed(status: OSStatus(eventInternalErr)).log()
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
      KeyCommandError.unregistrationFailed(status: status).log()
    }
    UserDefaults.standard.removeObject(forKey: name.combinedValue)
    isRegistered = false
    if shouldReregister {
      register()
    }
  }
  
  func removeKeyAndModifiers() {
    withoutChangingRegistrationState {
      $0.key = nil
      $0.modifiers.removeAll()
    }
    if isRegistered {
      unregister(shouldReregister: true)
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
  
  func withoutChangingRegistrationState(do body: (Proxy) throws -> Void) rethrows {
    blockRegistrationChanges = true
    defer {
      blockRegistrationChanges = false
    }
    try body(self)
  }
  
  func performObservations(matching eventType: KeyCommand.EventType?) {
    keyCommandObservations.performObservations(matching: eventType)
  }
  
  func performObservations(where predicate: (KeyCommand.EventType) throws -> Bool) rethrows {
    try keyCommandObservations.performObservations(where: predicate)
  }
  
  deinit {
    unregister()
  }
}

extension Proxy: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(objectIdentifier)
  }
}

extension Proxy: Equatable {
  static func == (lhs: Proxy, rhs: Proxy) -> Bool {
    lhs.objectIdentifier == rhs.objectIdentifier
  }
}

// MARK: - ProxyStorage

typealias ProxyStorage = Set<Proxy>

extension Set where Element == Proxy {
  private static var all = Self()
  
  static func proxy(with identifier: UInt32) -> Proxy? {
    all.first { $0.identifier.id == identifier }
  }
  
  static func proxy(with name: KeyCommand.Name) -> Proxy? {
    all.first { $0.name == name }
  }
  
  static func store(_ proxy: Proxy) {
    all.update(with: proxy)
  }
  
  static func remove(_ proxy: Proxy) {
    all.remove(proxy)
  }
}
