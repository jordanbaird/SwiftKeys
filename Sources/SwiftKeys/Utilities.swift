//===----------------------------------------------------------------------===//
//
// Utilities.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit
import OSLog

// MARK: - Functions

@discardableResult
func logError(_ error: EventError) -> String {
  let message = "[Error code \(error.code)] \(error.message)"
  if #available(macOS 10.14, *) {
    os_log(.error, "%@", message)
  } else if #available(macOS 10.12, *) {
    os_log("%@", type: .error, message)
  } else {
    NSLog("%@", message)
  }
  return message
}

// MARK: - Constraint

struct Constraint {
  fileprivate let base: NSLayoutConstraint
  fileprivate let view: NSView
  
  fileprivate let originalTranslates: Bool
  
  private init(_ base: NSLayoutConstraint, _ view: NSView) {
    self.base = base
    self.view = view
    originalTranslates = view.translatesAutoresizingMaskIntoConstraints
  }
  
  init(
    _ attribute1: NSLayoutConstraint.Attribute,
    of view1: NSView,
    to attribute2: NSLayoutConstraint.Attribute,
    of view2: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: attribute1,
      relatedBy: relation,
      toItem: view2,
      attribute: attribute2,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    _ attribute: NSLayoutConstraint.Attribute,
    of view: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view,
      attribute: attribute,
      relatedBy: relation,
      toItem: nil,
      attribute: attribute,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view)
  }
  
  func activate() {
    view.translatesAutoresizingMaskIntoConstraints = false
    base.isActive = true
  }
  
  func deactivate() {
    base.isActive = false
    view.translatesAutoresizingMaskIntoConstraints = originalTranslates
  }
}

// MARK: - EventError

enum EventError: Error {
  case custom(code: OSStatus, message: String)
  
  case decodingFailed(code: OSStatus)
  case encodingFailed(code: OSStatus)
  
  case installationFailed(code: OSStatus)
  
  case registrationFailed(code: OSStatus)
  case unregistrationFailed(code: OSStatus)
  
  var message: String {
    switch self {
    case .installationFailed: return "An error occurred while installing event handler."
    case .registrationFailed: return "An error occurred while registering a key event."
    case .unregistrationFailed: return "An error occurred while unregistering a key event."
    case .encodingFailed: return "An error occurred while encoding a key event."
    case .decodingFailed: return "An error occurred while decoding a key event."
    case .custom(_, let message): return message
    }
  }
  
  var code: OSStatus {
    switch self {
    case .installationFailed(let code): return code
    case .registrationFailed(let code): return code
    case .unregistrationFailed(let code): return code
    case .encodingFailed(let code): return code
    case .decodingFailed(let code): return code
    case .custom(let code, _): return code
    }
  }
}

// MARK: - EventMonitor

struct EventMonitor {
  var handler: (NSEvent) -> NSEvent?
  
  var mask: NSEvent.EventTypeMask
  
  var monitor: Any?
  
  init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> NSEvent?) {
    self.handler = handler
    self.mask = mask
  }
  
  mutating func start() {
    guard monitor == nil else { return }
    monitor = NSEvent.addLocalMonitorForEvents(matching: mask, handler: handler)
  }
  
  mutating func stop() {
    guard monitor != nil else { return }
    NSEvent.removeMonitor(monitor as Any)
    monitor = nil
  }
}

// MARK: - IdentifiableWrapper

private var rng = SystemRandomNumberGenerator()
protocol IdentifiableWrapper: Hashable {
  associatedtype Value
  typealias IDGenerator = SystemRandomNumberGenerator
  typealias Identifier = UInt64
  var id: Identifier { get }
  var value: Value { get }
}

extension IdentifiableWrapper {
  static var idGenerator: IDGenerator {
    get { rng }
    set { rng = newValue }
  }
}

extension IdentifiableWrapper {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

extension IdentifiableWrapper {
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension NSView {
  func set<T>(_ property: ReferenceWritableKeyPath<CALayer, T>, to value: T) {
    wantsLayer = true
    layer?[keyPath: property] = value
  }
  
  func set<T>(_ property: ReferenceWritableKeyPath<NSView, T>, to value: T) {
    self[keyPath: property] = value
  }
}
