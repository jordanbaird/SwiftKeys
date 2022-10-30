//===----------------------------------------------------------------------===//
//
// Utilities.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit
import OSLog

// MARK: - KeyCommandError

struct KeyCommandError: Error {
  let code: OSStatus
  let message: String
}

extension KeyCommandError {
  @discardableResult
  func log() -> String {
    let message = "[Error code \(code)] \(message)"
    Logger.error.send(message: message)
    return message
  }
}

extension KeyCommandError {
  static func decodingFailed(code: OSStatus) -> Self {
    .init(
      code: code,
      message: "An error occurred while decoding a key command.")
  }
  
  static func encodingFailed(code: OSStatus) -> Self {
    .init(
      code: code,
      message: "An error occurred while encoding a key command.")
  }
  
  static func installationFailed(code: OSStatus) -> Self {
    .init(
      code: code,
      message: "An error occurred while installing event handler.")
  }
  
  static func uninstallationFailed(code: OSStatus) -> Self {
    .init(
      code: code,
      message: "An error occurred while uninstalling event handler.")
  }
  
  static func registrationFailed(code: OSStatus) -> Self {
    .init(
      code: code,
      message: "An error occurred while registering a key command.")
  }
  static func unregistrationFailed(code: OSStatus) -> Self {
    .init(
      code: code,
      message: "An error occurred while unregistering a key command.")
  }
  
  static func systemRetrievalFailed(code: OSStatus) -> Self {
    .init(
      code: code,
      message: "An error occurred while retrieving system reserved key commands.")
  }
}

// MARK: - EventMonitor

struct EventMonitor {
  private var handler: (NSEvent) -> NSEvent?
  private var mask: NSEvent.EventTypeMask
  private var monitor: Any?
  
  init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> NSEvent?) {
    self.handler = handler
    self.mask = mask
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

// MARK: - IdentifiableWrapper

var rng = SystemRandomNumberGenerator()

protocol IdentifiableWrapper: Hashable {
  associatedtype Value
  associatedtype Identifier: Hashable
  var id: Identifier { get }
  var value: Value { get }
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

protocol IdentifiableObservation: IdentifiableWrapper where Value == () -> Void { }

extension IdentifiableObservation {
  var perform: () -> Void { value }
}

struct AnyIdentifiableObservation: IdentifiableObservation {
  let base: Any
  let id: AnyHashable
  let value: () -> Void
  
  init<T: IdentifiableObservation>(_ base: T) {
    self.base = base
    id = base.id
    value = base.value
  }
}

// MARK: - Logger

/// A wrapper for the unified logging system.
struct Logger {
  let log: OSLog
  let level: OSLogType
  
  /// Sends a message to the logging system using the given logger.
  static func send(logger: Self = .default, message: String) {
    logger.send(message: message)
  }
  
  /// Sends a message to the logging system using the given logger.
  static func send(logger: Self = .default, @LogMessageBuilder message: () -> String) {
    logger.send(message: message)
  }
  
  /// Sends a message to the logging system using this logger's log object and level.
  func send(message: String) {
    os_log("%@", log: log, type: level, message)
  }
  
  /// Sends a message to the logging system using this logger's log object and level.
  func send(@LogMessageBuilder message: () -> String) {
    send(message: message())
  }
  
  func callAsFunction(@LogMessageBuilder message: () -> String) {
    send(message: message)
  }
  
  func callAsFunction(message: String) {
    send(message: message)
  }
}

extension Logger {
  /// The default logger.
  static let `default` = Self(log: .default, level: .default)
  
  /// A logger for error messages.
  static let error = Self(log: .default, level: .error)
  
  /// A logger for debug messages.
  static let debug = Self(log: .default, level: .debug)
  
  /// A logger for faults.
  static let fault = Self(log: .default, level: .fault)
  
  /// A logger for informative messages.
  static let info = Self(log: .default, level: .info)
}

// MARK: - LogMessageBuilder

/// A result builder for log messages.
@resultBuilder
struct LogMessageBuilder {
  static func buildBlock(_ components: String...) -> String {
    components.joined(separator: " ")
  }
}
