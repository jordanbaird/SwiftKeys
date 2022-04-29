//===----------------------------------------------------------------------===//
//
// KeyRecorder.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit

/// A view that can record key events.
///
/// Start by creating a `KeyEvent`. You can then use it to initialize a
/// `KeyRecorder` instance, which will update the event whenever a new key
/// combination is recorded. You can also observe the event, and perform
/// actions on both key-down _and_ key-up.
///
/// ```swift
/// let event = KeyEvent(name: "SomeEvent")
/// let recorder = KeyRecorder(keyEvent: event)
///
/// event.observe(.keyDown) {
///     print("DOWN")
/// }
/// event.observe(.keyUp) {
///     print("UP")
/// }
/// ```
public final class KeyRecorder: NSView {
  private let cornerRadius = 5.5
  private let segmentedControl: SegmentedControl
  
  @available(macOS 10.11, *)
  private lazy var backingView: NSVisualEffectView = {
    let view = NSVisualEffectView(frame: frame)
    view.blendingMode = .behindWindow
    view.material = .sidebar
    view.wantsLayer = true
    view.layer?.cornerRadius = cornerRadius
    return view
  }()
  
  private var _hasBackingView = true
  
  /// A Boolean value that indicates whether the recorder is drawn with
  /// a backing visual effect view.
  @available(macOS 10.11, *)
  public var hasBackingView: Bool {
    get { _hasBackingView }
    set {
      removeBackingView()
      if newValue {
        addBackingView()
      }
    }
  }
  
  /// A Boolean value that indicates whether the recorder reacts to mouse events.
  ///
  /// The value of this property is true if the recorder responds to mouse events;
  /// otherwise, false.
  public var isEnabled: Bool {
    get { segmentedControl.isEnabled }
    set { segmentedControl.isEnabled = newValue }
  }
  
  /// Creates a recorder for the given key event.
  ///
  /// Whenever the event records a key combination, the event will update its value.
  public init(keyEvent: KeyEvent) {
    segmentedControl = .init(keyEvent: keyEvent)
    super.init(frame: segmentedControl.frame)
    Constraint(widthOf: self, constant: segmentedControl.frame.width).activate()
    Constraint(heightOf: self, constant: segmentedControl.frame.height).activate()
    addSubview(segmentedControl)
  }
  
  /// Creates a recorder for the key event with the given name.
  ///
  /// If an event with the name does not exist, a blank event will be created.
  /// As soon as the recorder records a key combination, the event will assume
  /// that combination's value.
  public convenience init(name: KeyEvent.Name) {
    self.init(keyEvent: .init(name: name))
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("KeyRecorder must be created programmatically.")
  }
  
  @available(macOS 10.11, *)
  private func addBackingView() {
    guard let superview = superview else {
      return
    }
    superview.addSubview(backingView, positioned: .below, relativeTo: self)
    Constraint(centerXOf: backingView, to: .centerX, of: self).activate()
    Constraint(centerYOf: backingView, to: .centerY, of: self).activate()
    Constraint(widthOf: backingView, to: .width, of: self, constant: -2).activate()
    Constraint(heightOf: backingView, to: .height, of: self, constant: -2).activate()
  }
  
  @available(macOS 10.11, *)
  private func removeBackingView() {
    backingView.removeFromSuperview()
  }
  
  public override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if
      #available(macOS 10.11, *),
      hasBackingView
    {
      addBackingView()
    }
  }
}

extension KeyRecorder {
  class SegmentedControl: NSSegmentedControl {
    private enum RecordingState {
      case recording
      case idle
    }
    
    private enum Label: String {
      case typeShortcut = "Type shortcut"
      case recordShortcut = "Record shortcut"
      case keyEvent = "*****"
    }
    
    private struct FailureReason: Equatable {
      static let noFailure = Self(message: "There is nothing wrong.")
      
      static let needsModifiers = Self(message: """
        Please include at least one modifier key (Shift, Control, Option, Command).
        """)
      
      static let onlyShift = Self(message: """
        Shift by itself is not a valid modifier key. Please include at least one \
        additional modifier key (Control, Option, Command).
        """)
      
      let message: String
      
      var failureCount = 0 {
        didSet {
          if
            self == .noFailure,
            failureCount != 0
          {
            failureCount = 0
          }
        }
      }
      
      static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.message == rhs.message
      }
      
      mutating func incrementFailureCount() {
        failureCount += 1
      }
    }
    
    let proxy: EventProxy
    
    private var failureReason = FailureReason.noFailure {
      didSet {
        if failureReason.failureCount >= 3 {
          let alert = NSAlert()
          alert.messageText = failureReason.message
          alert.window.isMovable = false
          alert.runModal()
          self.failureReason = .noFailure
        }
      }
    }
    
    private lazy var keyDownMonitor = EventMonitor(mask: .keyDown) { [weak self] event in
      guard let self = self else {
        return event
      }
      guard let key = KeyEvent.Key(Int(event.keyCode)) else {
        NSSound.beep()
        return nil
      }
      let modifiers = KeyEvent.Modifier.fromFlags(event.modifierFlags)
      guard !modifiers.isEmpty else {
        NSSound.beep()
        self.setFailureReason(.needsModifiers)
        self.failureReason.incrementFailureCount()
        return nil
      }
      guard modifiers != [.shift] else {
        NSSound.beep()
        self.setFailureReason(.onlyShift)
        self.failureReason.incrementFailureCount()
        return nil
      }
      self.record(key: key, modifiers: modifiers)
      self.setFailureReason(.noFailure)
      self.deselectAll()
      return nil
    }
    
    private let imageDelete: NSImage = {
      let image = NSImage(named: NSImage.stopProgressFreestandingTemplateName)!
      image.isTemplate = true
      return image
    }()
    
    private let imageEscape: NSImage = {
      let escapeKeyCode = 0x238B
      let string = NSString(format: "%C", escapeKeyCode)
      var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.white]
      if #available(macOS 10.11, *) {
        attributes[.font] = NSFont.systemFont(ofSize: 16, weight: .thin)
      } else {
        attributes[.font] = NSFont.systemFont(ofSize: 16)
      }
      let stringSize = string.size(withAttributes: attributes)
      let image = NSImage(
        size: .init(width: stringSize.height, height: stringSize.height),
        flipped: false
      ) {
        string.draw(
          in: .init(origin: .zero, size: stringSize).centered(in: $0),
          withAttributes: attributes)
        return true
      }
      image.isTemplate = true
      return image
    }()
    
    private var imageRecord: NSImage {
      let size = NSSize(width: 13, height: 13)
      let image = NSImage(size: size, flipped: false) {
        NSBezierPath(ovalIn: $0.insetBy(dx: 2.5, dy: 2.5)).fill()
        NSBezierPath(ovalIn: $0.insetBy(dx: 0.5, dy: 0.5)).stroke()
        return true
      }
      image.isTemplate = true
      return image
    }
    
    private var recordingState = RecordingState.idle {
      didSet {
        updateVisualAppearance()
        if recordingState == .recording {
          deselectAll()
          setSelected(true, forSegment: 0)
          failureReason = .noFailure
          keyDownMonitor.start()
        } else if recordingState == .idle {
          keyDownMonitor.stop()
        }
      }
    }
    
    /// Creates a recorder for the given key event.
    init(keyEvent: KeyEvent) {
      proxy = keyEvent.proxy
      super.init(frame: .init(origin: .zero, size: .init(width: 140, height: 24)))
      sharedInit()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("KeyRecorder must be created programmatically.")
    }
    
    private func sharedInit() {
      target = self
      action = #selector(controlWasPressed(_:))
      segmentCount = 2
      deselectAll()
      setImageScaling(.scaleProportionallyDown, forSegment: 0)
      setImageScaling(.scaleProportionallyDown, forSegment: 1)
      setWidth(frame.width - frame.height, forSegment: 0)
      setWidth(frame.height, forSegment: 1)
      proxy.observeRegistrationState(updateVisualAppearance)
    }
    
    @objc
    private func controlWasPressed(_ sender: SegmentedControl) {
      switch recordingState {
      case .recording:
        if sender.selectedSegment == 1 {
          recordingState = .idle
        }
      case .idle:
        if sender.selectedSegment == 0 {
          recordingState = .recording
        } else if sender.selectedSegment == 1 {
          if proxy.isRegistered {
            proxy.unregister()
          } else {
            recordingState = .recording
          }
        }
      }
      if recordingState == .idle {
        deselectAll()
      }
      updateVisualAppearance()
    }
    
    private func record(key: KeyEvent.Key, modifiers: [KeyEvent.Modifier]) {
      proxy.mutateWithoutChangingRegistrationState {
        $0.key = key
        $0.modifiers = modifiers
      }
      proxy.register()
      recordingState = .idle
    }
    
    private func updateVisualAppearance() {
      setLabel(forState: recordingState)
      setImage(forState: recordingState)
    }
    
    private func setLabel(_ label: Label) {
      var string = ""
      if
        label == .keyEvent,
        proxy.isRegistered,
        let key = proxy.key
      {
        string = proxy.modifiers.map(\.stringValue).joined()
        string.append(key.stringValue.uppercased(with: .current))
      } else {
        string = label.rawValue
      }
      setLabel(string, forSegment: 0)
    }
    
    private func setLabel(forState state: RecordingState) {
      switch state {
      case .recording:
        setLabel(.typeShortcut)
      case .idle:
        if proxy.isRegistered {
          setLabel(.keyEvent)
        } else {
          setLabel(.recordShortcut)
        }
      }
    }
    
    private func setImage(forState state: RecordingState) {
      switch state {
      case .recording:
        setImage(imageEscape, forSegment: 1)
      case .idle:
        if proxy.isRegistered {
          setImage(imageDelete, forSegment: 1)
        } else {
          setImage(imageRecord, forSegment: 1)
        }
      }
    }
    
    private func deselectAll() {
      for n in 0..<segmentCount {
        setSelected(false, forSegment: n)
      }
    }
    
    private func setFailureReason(_ failureReason: FailureReason) {
      if self.failureReason != failureReason {
        self.failureReason = failureReason
      }
    }
    
    public override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      updateVisualAppearance()
    }
  }
}

extension KeyEvent.Modifier {
  fileprivate static func fromFlags(_ flags: NSEvent.ModifierFlags) -> [Self] {
    var modifiers = [Self]()
    // NOTE: Keep the order of these statements.
    if flags.contains(.control) {
      modifiers.append(.control)
    }
    if flags.contains(.option) {
      modifiers.append(.option)
    }
    if flags.contains(.shift) {
      modifiers.append(.shift)
    }
    if flags.contains(.command) {
      modifiers.append(.command)
    }
    return modifiers
  }
}

extension NSRect {
  fileprivate mutating func center(in otherRect: NSRect) {
    origin = .init(x: otherRect.midX - width / 2, y: otherRect.midY - height / 2)
  }
  
  fileprivate func centered(in otherRect: NSRect) -> NSRect {
    var copy = self
    copy.center(in: otherRect)
    return copy
  }
}
