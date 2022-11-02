//===----------------------------------------------------------------------===//
//
// Logger.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import OSLog

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
  ///   - message: The message that will be sent to the
  ///     unified logging system.
  /// - Returns: A discardable copy of the message.
  @discardableResult
  static func send(_ logger: Self = .default, _ message: String) -> String {
    logger.send(message)
  }
  
  /// Sends a message to the logging system using the logger's
  /// log object and level.
  ///
  /// - Parameter message: The message that will be sent to the
  ///   unified logging system.
  /// - Returns: A discardable copy of the message.
  @discardableResult
  func send(_ message: String) -> String {
    os_log("%@", log: log, type: level, message)
    return message
  }
}

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
