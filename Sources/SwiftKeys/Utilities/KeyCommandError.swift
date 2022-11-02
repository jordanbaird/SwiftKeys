//===----------------------------------------------------------------------===//
//
// KeyCommandError.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

typealias OSStatus = Int32

struct KeyCommandError: Error {
  let status: OSStatus
  let message: String
}

extension KeyCommandError {
  @discardableResult
  func log() -> String {
    Logger.send(.error, "[OSStatus \(status)] \(message)")
  }
}

extension KeyCommandError {
  static func encodingFailed(status: OSStatus) -> Self {
    .init(
      status: status,
      message: "Key command encoding failed.")
  }
  
  static func installationFailed(status: OSStatus) -> Self {
    .init(
      status: status,
      message: "Event handler installation failed.")
  }
  
  static func uninstallationFailed(status: OSStatus) -> Self {
    .init(
      status: status,
      message: "Event handler uninstallation failed.")
  }
  
  static func registrationFailed(status: OSStatus) -> Self {
    .init(
      status: status,
      message: "Key command registration failed.")
  }
  
  static func unregistrationFailed(status: OSStatus) -> Self {
    .init(
      status: status,
      message: "Key command unregistration failed.")
  }
  
  static func systemRetrievalFailed(status: OSStatus) -> Self {
    .init(
      status: status,
      message: "System reserved key command retrieval failed.")
  }
}
