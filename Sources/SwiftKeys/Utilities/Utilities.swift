//
// Utilities.swift
// SwiftKeys
//

import Cocoa
import OSLog

// MARK: - CALayer

extension CALayer {
    static func roundedRectBorder(
        frame: CGRect,
        color: NSColor,
        lineWidth: CGFloat = 1,
        cornerRadius: CGFloat
    ) -> CALayer {
        let layer = CAShapeLayer()
        layer.frame = frame
        layer.fillColor = .clear
        layer.strokeColor = color.cgColor
        layer.lineWidth = lineWidth
        layer.path = .init(
            roundedRect: frame.insetBy(dx: lineWidth, dy: lineWidth),
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        return layer
    }

    static func roundedRectBorder(for control: NSSegmentedControl) -> CALayer {
        roundedRectBorder(frame: control.bounds, color: .controlColor, lineWidth: 1, cornerRadius: 6)
    }

    static func segmentSplitter(for control: NSSegmentedControl, afterSegment segment: Int) -> CALayer {
        let layer = CAShapeLayer()
        layer.frame = control.bounds
        layer.lineWidth = 1
        if #available(macOS 10.14, *) {
            layer.strokeColor = NSColor.separatorColor.cgColor
        } else {
            layer.strokeColor = NSColor.quaternaryLabelColor.cgColor
        }

        let path = CGMutablePath()

        let segment = max(min(segment, control.segmentCount), 0)
        let xPosition: CGFloat = (0...segment).reduce(into: 0) {
            $0 += control.width(forSegment: $1)
        }

        path.move(
            to: .init(
                x: xPosition,
                y: (layer.frame.midY + layer.frame.maxY) / 2)
        )
        path.addLine(
            to: .init(
                x: xPosition,
                y: (layer.frame.minY + layer.frame.midY) / 2)
        )

        layer.path = path

        return layer
    }
}

// MARK: - EventMonitor

struct EventMonitor {
    private var monitor: Any?
    private var mask: NSEvent.EventTypeMask
    private var handler: (NSEvent) -> NSEvent?

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> NSEvent?) {
        self.mask = mask
        self.handler = handler
    }

    mutating func start() {
        guard monitor == nil else {
            return
        }
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: mask,
            handler: handler)
    }

    mutating func stop() {
        guard monitor != nil else {
            return
        }
        NSEvent.removeMonitor(monitor as Any)
        monitor = nil
    }
}

// MARK: - HandlerWrapper

/// The existential type for an identifiable wrapper around a block of code.
protocol HandlerWrapper: Equatable, Hashable {
    associatedtype Value

    /// The identifying element of the handler.
    var id: AnyHashable { get }

    /// Creates a handler with the given identifier and code block.
    init(id: AnyHashable, block: @escaping () -> Value)

    /// Performs the handler's code block.
    func perform() -> Value
}

// MARK: HandlerWrapper Initializers
extension HandlerWrapper {
    /// Creates a handler with the given code block.
    init(block: @escaping () -> Value) {
        self.init(id: UUID(), block: block)
    }
}

// MARK: HandlerWrapper: Equatable
extension HandlerWrapper {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: HandlerWrapper: Hashable
extension HandlerWrapper {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Handler

/// A concrete type for an identifiable wrapper around a block of code.
struct Handler<Value>: HandlerWrapper {
    let id: AnyHashable
    private let block: () -> Value

    init(id: AnyHashable, block: @escaping () -> Value) {
        self.id = id
        self.block = block
    }

    func perform() -> Value {
        block()
    }
}

// MARK: - VoidHandler

/// An alias for an identifiable wrapper around a block of code whose
/// return value is `Void`.
typealias VoidHandler = Handler<Void>

// MARK: - Collection<HandlerWrapper>

extension Collection where Element: HandlerWrapper {
    /// Performs every handler in the collection and returns the results.
    @discardableResult
    func performAll() -> [Element.Value] {
        map { $0.perform() }
    }
}

// MARK: - KeyCommandError

/// An error type that represents a failure during the setup or
/// teardown of a `KeyCommand`.
struct KeyCommandError: Error {
    /// The `OSStatus` value of the error.
    let status: OSStatus

    /// The error's message.
    let message: String
}

// MARK: KeyCommandError Log
extension KeyCommandError {
    /// Logs the error to the unified logging system.
    @discardableResult
    func log() -> String {
        Logger.send(.error, "[OSStatus \(status)] \(message)")
    }
}

// MARK: KeyCommandError Static Members
extension KeyCommandError {
    static func encodingFailed(status: OSStatus) -> Self {
        .init(
            status: status,
            message: "Key command encoding failed."
        )
    }

    static func installationFailed(status: OSStatus) -> Self {
        .init(
            status: status,
            message: "Event handler installation failed."
        )
    }

    static func uninstallationFailed(status: OSStatus) -> Self {
        .init(
            status: status,
            message: "Event handler uninstallation failed."
        )
    }

    static func registrationFailed(status: OSStatus) -> Self {
        .init(
            status: status,
            message: "Key command registration failed."
        )
    }

    static func unregistrationFailed(status: OSStatus) -> Self {
        .init(
            status: status,
            message: "Key command unregistration failed."
        )
    }

    static func systemRetrievalFailed(status: OSStatus) -> Self {
        .init(
            status: status,
            message: "System reserved key command retrieval failed."
        )
    }
}

// MARK: - Logger

/// A wrapper for the unified logging system.
struct Logger {
    /// The logger's corresponding object in the unified logging system.
    let log: OSLog

    /// The logger's level in the unified logging system.
    let level: OSLogType

    /// Sends a message to the logging system using the given logger.
    ///
    /// - Parameters:
    ///   - logger: The logger to use to send the message.
    ///   - message: The message that will be sent to the unified logging system.
    /// - Returns: A discardable copy of the message.
    @discardableResult
    static func send(_ logger: Self = .default, _ message: String) -> String {
        logger.send(message)
    }

    /// Sends a message to the logging system using the logger's log object and level.
    ///
    /// - Parameter message: The message that will be sent to the unified logging system.
    /// - Returns: A discardable copy of the message.
    @discardableResult
    func send(_ message: String) -> String {
        os_log("%@", log: log, type: level, message)
        return message
    }
}

// MARK: Logger Static Members
extension Logger {
    /// The default logger.
    static let `default` = Self(log: .default, level: .default)

    /// The logger for error messages.
    static let error = Self(log: .default, level: .error)

    /// The logger for debug messages.
    static let debug = Self(log: .default, level: .debug)

    /// The logger for faults.
    static let fault = Self(log: .default, level: .fault)

    /// The logger for informative messages.
    static let info = Self(log: .default, level: .info)
}

// MARK: - NotificationCenterObserver

class NotificationCenterObserver {
    private var handlers = [Notification.Name: [VoidHandler]]()

    init() { }

    @discardableResult
    func observe(_ name: Notification.Name, block: @escaping () -> Void) -> NotificationCenterObserver {
        let handler = VoidHandler(block: block)
        if var handlersForName = handlers[name] {
            handlersForName.append(handler)
            handlers[name] = handlersForName
        } else {
            handlers[name] = [handler]
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didReceiveNotification(_:)),
                name: name,
                object: nil)
        }
        return self
    }

    func removeObservations(for name: Notification.Name) {
        handlers.removeValue(forKey: name)
    }

    func isObserving(_ name: Notification.Name) -> Bool {
        handlers[name] != nil
    }

    @objc
    private func didReceiveNotification(_ notification: Notification) {
        for handler in handlers[notification.name, default: []] {
            handler.perform()
        }
    }
}

// MARK: - NSKeyValueObservation

extension NSKeyValueObservation {
    func store<C: RangeReplaceableCollection<NSKeyValueObservation>>(in collection: inout C) {
        collection.append(self)
    }

    func store(in set: inout Set<NSKeyValueObservation>) {
        set.insert(self)
    }
}

// MARK: - Storage

/// A type that uses object association to store external values.
class Storage<Value> {
    private let policy: AssociationPolicy

    private var key: UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }

    /// Creates a storage object that stores values of the given type,
    /// using the given association policy.
    init(
        _ type: Value.Type = Value.self,
        _ policy: AssociationPolicy = .retainNonatomic
    ) {
        self.policy = policy
    }

    /// Gets or sets a value for the given object.
    subscript<Object: AnyObject>(_ object: Object) -> Value? {
        get { objc_getAssociatedObject(object, key) as? Value }
        set { objc_setAssociatedObject(object, key, newValue, policy.objcValue) }
    }
}

// MARK: - Storage AssociationPolicy

extension Storage {
    /// Available policies to use for object association.
    enum AssociationPolicy {
        /// A weak reference to the associated object.
        case assign

        /// The associated object is copied atomically.
        case copy

        /// The associated object is copied nonatomically.
        case copyNonatomic

        /// A strong reference to the associated object that is made atomically.
        case retain

        /// A strong reference to the associated object that is made nonatomically.
        case retainNonatomic

        fileprivate var objcValue: objc_AssociationPolicy {
            switch self {
            case .assign:
                return .OBJC_ASSOCIATION_ASSIGN
            case .copy:
                return .OBJC_ASSOCIATION_COPY
            case .copyNonatomic:
                return .OBJC_ASSOCIATION_COPY_NONATOMIC
            case .retain:
                return .OBJC_ASSOCIATION_RETAIN
            case .retainNonatomic:
                return .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            }
        }
    }
}
