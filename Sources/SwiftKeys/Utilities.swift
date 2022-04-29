//===----------------------------------------------------------------------===//
//
// Utilities.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit
import Carbon.HIToolbox
import OSLog

// MARK: - Functions

/// Logs an error to the console using (if applicable) the `OSLog` unified logging
/// system. If `OSLog` is not supported, the error will be logged using `NSLog`.
func logError(_ error: EventError) {
  let message = "[Error code \(error.code)] \(error.message)"
  if #available(macOS 10.14, *) {
    os_log(.error, "%@", message)
  } else if #available(macOS 10.12, *) {
    os_log("%@", type: .error, message)
  } else {
    NSLog("%@", message)
  }
}

enum EventError: Error {
  case custom(code: OSStatus, message: String)
  
  case decodingFailed(code: OSStatus)
  case encodingFailed(code: OSStatus)
  
  case installationFailed(code: OSStatus)
  
  case registrationFailed(code: OSStatus)
  case unregistrationFailed(code: OSStatus)
  
  
  var message: String {
    switch self {
    case .installationFailed:
      return "An error occurred while installing event handler."
    case .registrationFailed:
      return "An error occurred while registering a key event."
    case .unregistrationFailed:
      return "An error occurred while unregistering a key event."
    case .encodingFailed:
      return "An error occurred while encoding a key event."
    case .decodingFailed:
      return "An error occurred while decoding a key event."
    case .custom(_, let message):
      return message
    }
  }
  
  var code: OSStatus {
    switch self {
    case .installationFailed(let code):
      return code
    case .registrationFailed(let code):
      return code
    case .unregistrationFailed(let code):
      return code
    case .encodingFailed(let code):
      return code
    case .decodingFailed(let code):
      return code
    case .custom(let code, _):
      return code
    }
  }
}

// MARK: - EventType

/// Constants that specify the type of a key event.
///
/// Pass these into a key event's `observe(_:handler:)` method. The closure you
/// provide in that method will be called whenever an event of this type is posted.
///
/// ```swift
/// let event = KeyEvent(
///     name: "Cheese",
///     key: .leftArrow,
///     modifiers: [.command, .option])
///
/// event.observe(.keyDown) {
///     print("KEY DOWN")
/// }
///
/// event.observe(.keyUp) {
///     print("KEY UP")
/// }
///
/// // Note that `observe(_:handler:)` can be called multiple
/// // times, each invoking different closures.
/// ```
public enum EventType {
  /// The key is released.
  case keyUp
  /// The key is pressed.
  case keyDown
  
  init(_ eventRef: EventRef!) {
    switch Int(GetEventKind(eventRef)) {
    case kEventHotKeyPressed: self = .keyDown
    case kEventHotKeyReleased: self = .keyUp
    default: fatalError("Invalid event reference.")
    }
  }
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
    widthOf view1: NSView,
    to attribute: NSLayoutConstraint.Attribute,
    of view2: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .width,
      relatedBy: relation,
      toItem: view2,
      attribute: .width,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    widthOf view1: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .width,
      relatedBy: relation,
      toItem: nil,
      attribute: .width,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    heightOf view1: NSView,
    to attribute: NSLayoutConstraint.Attribute,
    of view2: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .height,
      relatedBy: relation,
      toItem: view2,
      attribute: .height,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    heightOf view1: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .height,
      relatedBy: relation,
      toItem: nil,
      attribute: .height,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    centerXOf view1: NSView,
    to attribute: NSLayoutConstraint.Attribute,
    of view2: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .centerX,
      relatedBy: relation,
      toItem: view2,
      attribute: .centerX,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    centerXOf view1: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .centerX,
      relatedBy: relation,
      toItem: nil,
      attribute: .centerX,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    centerYOf view1: NSView,
    to attribute: NSLayoutConstraint.Attribute,
    of view2: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .centerY,
      relatedBy: relation,
      toItem: view2,
      attribute: .centerY,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    centerYOf view1: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .centerY,
      relatedBy: relation,
      toItem: nil,
      attribute: .centerY,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    leadingOf view1: NSView,
    to attribute: NSLayoutConstraint.Attribute,
    of view2: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .leading,
      relatedBy: relation,
      toItem: view2,
      attribute: .leading,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    leadingOf view1: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .leading,
      relatedBy: relation,
      toItem: nil,
      attribute: .leading,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    trailingOf view1: NSView,
    to attribute: NSLayoutConstraint.Attribute,
    of view2: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .trailing,
      relatedBy: relation,
      toItem: view2,
      attribute: .trailing,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    trailingOf view1: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .trailing,
      relatedBy: relation,
      toItem: nil,
      attribute: .trailing,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    leftOf view1: NSView,
    to attribute: NSLayoutConstraint.Attribute,
    of view2: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .left,
      relatedBy: relation,
      toItem: view2,
      attribute: .left,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    leftOf view1: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .left,
      relatedBy: relation,
      toItem: nil,
      attribute: .left,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    rightOf view1: NSView,
    to attribute: NSLayoutConstraint.Attribute,
    of view2: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .right,
      relatedBy: relation,
      toItem: view2,
      attribute: .right,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    rightOf view1: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .right,
      relatedBy: relation,
      toItem: nil,
      attribute: .right,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    topOf view1: NSView,
    to attribute: NSLayoutConstraint.Attribute,
    of view2: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .top,
      relatedBy: relation,
      toItem: view2,
      attribute: .top,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    topOf view1: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .top,
      relatedBy: relation,
      toItem: nil,
      attribute: .top,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    bottomOf view1: NSView,
    to attribute: NSLayoutConstraint.Attribute,
    of view2: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .bottom,
      relatedBy: relation,
      toItem: view2,
      attribute: .bottom,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
  }
  
  init(
    bottomOf view1: NSView,
    relation: NSLayoutConstraint.Relation = .equal,
    multiplier: CGFloat = 1,
    constant: CGFloat = 0
  ) {
    let constraint = NSLayoutConstraint(
      item: view1,
      attribute: .bottom,
      relatedBy: relation,
      toItem: nil,
      attribute: .bottom,
      multiplier: multiplier,
      constant: constant)
    self.init(constraint, view1)
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
