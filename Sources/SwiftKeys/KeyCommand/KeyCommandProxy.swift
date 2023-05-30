//
// KeyCommandProxy.swift
// SwiftKeys
//

import Carbon.HIToolbox

final class KeyCommandProxy {

    // MARK: Static Properties

    private static var eventHandlerRef: EventHandlerRef?

    private static let eventTypes = [
        EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        ),
        EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyReleased)
        ),
    ]

    private static var proxyCount: UInt32 = 0

    private static let signature: OSType = NSHFSTypeCodeFromFileType("'SWKE'")

    static var isInstalled: Bool {
        eventHandlerRef != nil
    }

    // MARK: Instance Properties

    private var hotKeyRef: EventHotKeyRef?

    fileprivate let identifier = EventHotKeyID(signature: signature, id: proxyCount)

    var keyAndModifierChangeHandlers = Set<VoidHandler>()

    var registrationStateHandlers = Set<VoidHandler>()

    var keyCommandObservations = [KeyCommand.Observation]()

    let notificationCenterObserver = NotificationCenterObserver()

    private var blockRegistrationChanges = false

    private var lastKeyUpDate = Date()

    var menuIsOpen = false

    let name: KeyCommand.Name

    var isRegistered = false {
        didSet {
            registrationStateHandlers.performAll()
        }
    }

    var key: KeyCommand.Key? {
        didSet {
            // If already registered, we need to re-register for the new key.
            if isRegistered {
                unregister(shouldReregister: true)
            }
            keyAndModifierChangeHandlers.performAll()
        }
    }

    var modifiers = [KeyCommand.Modifier]() {
        didSet {
            // If already registered, we need to re-register for the new modifiers.
            if isRegistered {
                unregister(shouldReregister: true)
            }
            keyAndModifierChangeHandlers.performAll()
        }
    }

    // MARK: Initializers

    init(with name: KeyCommand.Name, storing shouldStore: Bool = false) {
        self.name = name
        Self.proxyCount += 1
        if shouldStore {
            ProxyStorage.store(self)
        }
    }

    // MARK: Install/Uninstall

    static func install() -> OSStatus {
        guard !isInstalled else {
            return noErr
        }

        let handler: EventHandlerUPP = { _, event, _ in
            guard let event else {
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
                &identifier
            )

            // Make sure the creation was successful.
            guard status == noErr else {
                return status
            }

            // Make sure the event is one of ours (a.k.a. if its signature lines up
            // with our signature), and that we have a stored proxy for the event.
            guard
                // swiftlint:disable:next prefer_self_in_static_references
                identifier.signature == KeyCommandProxy.signature,
                let proxy = ProxyStorage.proxy(with: identifier)
            else {
                return OSStatus(eventNotHandledErr)
            }

            // Create an array of event types, based on the current event.
            var eventTypes = [KeyCommand.EventType(event)]

            // Key up events should also send a double tap event, based on the time
            // between the most recent key up date and the current date. Observations
            // whose intervals fall within this time will be executed.
            if eventTypes == [.keyUp] {
                let currentDate = Date()
                eventTypes.append(.doubleTap(currentDate.timeIntervalSince(proxy.lastKeyUpDate)))
                proxy.lastKeyUpDate = currentDate
            }

            // Execute the proxy's stored observations.
            for eventType in eventTypes {
                proxy.performObservations { observationEventType in
                    switch observationEventType {
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
                        return observationEventType == eventType
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
            &eventHandlerRef
        )
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

    // MARK: Register/Unregister

    func register() {
        guard
            !blockRegistrationChanges,
            !modifiers.isEmpty,
            let key
        else {
            return
        }

        if isRegistered {
            // If already registered, we need to unregister first, or we'll end up
            // with two conflicting registrations.
            unregister()
        }

        // Always try to install. If we're already installed, this will return noErr.
        var status = Self.install()

        guard status == noErr else {
            KeyCommandError.installationFailed(status: status).log()
            return
        }

        status = RegisterEventHotKey(
            key.unsigned(),
            modifiers.unsigned(),
            identifier,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            KeyCommandError.registrationFailed(status: status).log()
            return
        }

        // We need to retain a reference to each proxy instance. The C function inside
        // of the `install()` method can't deal with context, so we can't inject or
        // reference `self`. We _do_ have a way to access the proxy's identifier, so we
        // can use that to store the proxy, then access the storage from inside the C
        // function.
        ProxyStorage.store(self)

        do {
            let data = try JSONEncoder().encode(KeyCommand(name: name))
            UserDefaults.standard.set(data, forKey: name.combinedValue)
        } catch {
            // If we made it this far, everything else worked properly, the command just
            // wasn't stored in UserDefaults.
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

    // MARK: Observing

    @discardableResult
    func observeRegistrationState(_ block: @escaping () -> Void) -> VoidHandler {
        let handler = VoidHandler(block: block)
        registrationStateHandlers.update(with: handler)
        return handler
    }

    func performObservations(matching eventType: KeyCommand.EventType?) {
        keyCommandObservations.performObservations(matching: eventType)
    }

    func performObservations(where predicate: (KeyCommand.EventType) throws -> Bool) rethrows {
        try keyCommandObservations.performObservations(where: predicate)
    }

    // MARK: Helpers

    /// Mutates the proxy, while blocking it from registering or unregistering.
    ///
    /// This is useful, for example, when executing multiple pieces of code that would
    /// normally cause the proxy to be automatically re-registered (examples of this
    /// include the `key` and `modifiers` properties). If we need to change both values,
    /// one after another, it would be inefficient to have to re-register after each
    /// change, so instead, we can make the changes inside of `block` and manually
    /// re-register afterwards.
    func withoutChangingRegistrationState(execute block: (KeyCommandProxy) throws -> Void) rethrows {
        blockRegistrationChanges = true
        defer {
            blockRegistrationChanges = false
        }
        try block(self)
    }

    func removeKeyAndModifiers() {
        withoutChangingRegistrationState { proxy in
            proxy.key = nil
            proxy.modifiers.removeAll()
        }
        if isRegistered {
            unregister(shouldReregister: true)
        }
    }

    @discardableResult
    func removeHandler(_ handler: VoidHandler) -> VoidHandler? {
        let h1 = keyAndModifierChangeHandlers.remove(handler)
        let h2 = registrationStateHandlers.remove(handler)
        return h1 ?? h2
    }

    // MARK: Deinitializer

    deinit {
        unregister()
    }
}

// MARK: KeyCommandProxy: Equatable
extension KeyCommandProxy: Equatable {
    static func == (lhs: KeyCommandProxy, rhs: KeyCommandProxy) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

// MARK: KeyCommandProxy: Hashable
extension KeyCommandProxy: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - ProxyStorage

typealias ProxyStorage = Set<KeyCommandProxy>

extension ProxyStorage {
    private static var all = Self()

    static func proxy(with identifier: EventHotKeyID) -> KeyCommandProxy? {
        all.first { $0.identifier.id == identifier.id }
    }

    static func proxy(with name: KeyCommand.Name) -> KeyCommandProxy? {
        all.first { $0.name == name }
    }

    static func store(_ proxy: KeyCommandProxy) {
        all.update(with: proxy)
    }

    static func remove(_ proxy: KeyCommandProxy) {
        all.remove(proxy)
    }
}
