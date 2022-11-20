//===----------------------------------------------------------------------===//
//
// KeyRecorder.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import AppKit

/// A view that can record key commands.
///
/// Start by creating a ``KeyCommand``. You can then use it
/// to initialize a key recorder, which will update the command
/// whenever a new key combination is recorded. You can also
/// observe the command to perform actions on key-down, key-up,
/// and double-tap events.
///
/// ```swift
/// let command = KeyCommand(name: "SomeCommand")
/// let recorder = KeyRecorder(command: command)
///
/// command.observe(.keyDown) {
///     print("DOWN")
/// }
/// command.observe(.keyUp) {
///     print("UP")
/// }
/// command.observe(.doubleTap(0.2)) {
///     print("DOUBLE")
/// }
/// ```
public final class KeyRecorder: NSControl {
  let segmentedControl: KeyRecorderSegmentedControl

  var backingView: NSVisualEffectView?

  var cornerRadius: CGFloat {
    switch bezelStyle {
    case .rounded: return 5.5
    case .flatBordered: return 5.5
    case .separated: return 6
    case .square: return 0
    }
  }

  /// A Boolean value that indicates whether the key recorder is
  /// drawn with a backing visual effect view.
  ///
  /// - Note: If ``bezelStyle-swift.property`` is ``BezelStyle-swift.enum/separated``,
  ///   this property is ignored.
  ///
  /// > Default value: `true`
  public var hasBackingView = true {
    didSet {
      needsDisplay = true
    }
  }

  /// The style of the key recorder's bezel.
  /// > Default value: ``BezelStyle-swift.enum/rounded``
  public var bezelStyle: BezelStyle = .rounded {
    didSet {
      needsDisplay = true
    }
  }

  /// The key command associated with the recorder.
  public var command: KeyCommand {
    .init(name: segmentedControl.proxy.name)
  }

  @available(*, deprecated, renamed: "command")
  public var keyEvent: KeyEvent { command }

  /// A Boolean value that indicates whether the key recorder reacts
  /// to mouse events.
  public override var isEnabled: Bool {
    get { segmentedControl.isEnabled }
    set { segmentedControl.isEnabled = newValue }
  }

  /// The string value of the key recorder's label.
  ///
  /// Setting this value allows you to customize the text that is
  /// displayed to the user.
  public override var stringValue: String {
    get { segmentedControl.label(forSegment: 0) ?? "" }
    set { segmentedControl.label = newValue }
  }

  /// The attributed string value of the key recorder's label.
  ///
  /// Setting this value allows you to customize the text that is
  /// displayed to the user.
  public override var attributedStringValue: NSAttributedString {
    get { segmentedControl.attributedLabel ?? .init(string: stringValue) }
    set { segmentedControl.attributedLabel = newValue }
  }

  /// The font of the key recorder's label.
  public override var font: NSFont? {
    get { segmentedControl.font }
    set { segmentedControl.font = newValue }
  }

  /// The alignment of the key recorder's label.
  public override var alignment: NSTextAlignment {
    get { segmentedControl.alignment(forSegment: 0) }
    set { segmentedControl.setAlignment(newValue, forSegment: 0) }
  }

  /// The appearance of the key recorder.
  public override var appearance: NSAppearance? {
    get { segmentedControl.appearance }
    set { segmentedControl.appearance = newValue }
  }

  /// Creates a key recorder for the given key command.
  ///
  /// Whenever a new key combination is recorded, the key and modifiers
  /// of the command will be updated to match.
  public init(command: KeyCommand) {
    segmentedControl = .init(command: command)
    super.init(frame: segmentedControl.frame)
    translatesAutoresizingMaskIntoConstraints = false
    widthAnchor.constraint(
      equalToConstant: segmentedControl.frame.width
    ).isActive = true
    heightAnchor.constraint(
      equalToConstant: segmentedControl.frame.height
    ).isActive = true
    addSubview(segmentedControl)
  }

  @available(*, deprecated, renamed: "init(command:)")
  public convenience init(keyEvent: KeyEvent) {
    self.init(command: keyEvent)
  }

  /// Creates a key recorder for the key command with the given name.
  ///
  /// If a command with the name does not exist, a blank command will be created.
  /// As soon as the key recorder records a key combination, the command will
  /// assume that combination's value.
  public convenience init(name: KeyCommand.Name) {
    self.init(command: .init(name: name))
  }

  @available(*, unavailable)
  override init(frame frameRect: NSRect) {
    fatalError("init(frame:) is unavailable.")
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("KeyRecorder must be created programmatically.")
  }

  public override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    wantsLayer = true
    layer?.cornerRadius = cornerRadius

    segmentedControl.segmentStyle = bezelStyle.rawValue
    backingView?.removeFromSuperview()

    if
      hasBackingView,
      bezelStyle != .separated
    {
      let backingView = NSVisualEffectView(frame: frame)
      self.backingView = backingView

      backingView.blendingMode = .behindWindow
      backingView.material = .sidebar
      backingView.wantsLayer = true
      backingView.layer?.cornerRadius = cornerRadius

      backingView.translatesAutoresizingMaskIntoConstraints = false
      addSubview(backingView, positioned: .below, relativeTo: self)
      backingView.centerXAnchor.constraint(
        equalTo: centerXAnchor
      ).isActive = true
      backingView.centerYAnchor.constraint(
        equalTo: centerYAnchor
      ).isActive = true
      backingView.widthAnchor.constraint(
        equalTo: widthAnchor,
        constant: bezelStyle.widthConstant
      ).isActive = true
      backingView.heightAnchor.constraint(
        equalTo: heightAnchor,
        constant: bezelStyle.heightConstant
      ).isActive = true
    }
  }
}

// MARK: - KeyRecorderSegmentedControl

extension KeyRecorder {
  class KeyRecorderSegmentedControl: NSSegmentedControl {
    let proxy: KeyCommandProxy

    var windowVisibilityObservation: NSKeyValueObservation?
    var keyDownMonitor: EventMonitor?

    var label: String? {
      didSet {
        updateVisualAppearance()
      }
    }

    var attributedLabel: NSAttributedString? {
      didSet {
        updateVisualAppearance()
      }
    }

    var failureReason = FailureReason.noFailure {
      didSet {
        if failureReason.failureCount >= 3 {
          recordingState = .idle
          failureReason.displayAlert()
          failureReason = .noFailure
        }
      }
    }

    let deleteImage: NSImage = {
      let image = NSImage(named: NSImage.stopProgressFreestandingTemplateName)!
      image.isTemplate = true
      return image
    }()

    let escapeImage: NSImage = {
      let escapeKeyCode = 0x238B
      let string = NSString(format: "%C", escapeKeyCode)
      var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.white]
      attributes[.font] = NSFont.systemFont(ofSize: 16, weight: .thin)
      let stringSize = string.size(withAttributes: attributes)
      let image = NSImage(
        size: .init(width: stringSize.height, height: stringSize.height),
        flipped: false
      ) {
        let centeredRect = NSRect(
          origin: .init(
            x: $0.midX - stringSize.width / 2,
            y: $0.midY - stringSize.height / 2),
          size: stringSize)
        string.draw(
          in: centeredRect,
          withAttributes: attributes)
        return true
      }
      image.isTemplate = true
      return image
    }()

    var recordImage: NSImage {
      let size = NSSize(width: 13, height: 13)
      let image = NSImage(size: size, flipped: false) {
        NSBezierPath(ovalIn: $0.insetBy(dx: 2.5, dy: 2.5)).fill()
        NSBezierPath(ovalIn: $0.insetBy(dx: 0.5, dy: 0.5)).stroke()
        return true
      }
      image.isTemplate = true
      return image
    }

    var recordingState = RecordingState.idle {
      didSet {
        updateVisualAppearance()
        deselectAll()
        if recordingState == .recording {
          setSelected(true, forSegment: 0)
          failureReason = .noFailure
          keyDownMonitor?.start()
          observeWindowVisibility()
        } else if recordingState == .idle {
          keyDownMonitor?.stop()
          windowVisibilityObservation = nil
        }
      }
    }

    init(command: KeyCommand) {
      proxy = command.proxy
      super.init(frame: .init(origin: .zero, size: .init(width: 140, height: 24)))
      sharedInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("KeyRecorder must be created programmatically.")
    }

    func sharedInit() {
      target = self
      action = #selector(controlWasPressed(_:))

      segmentCount = 2

      deselectAll()

      setImageScaling(.scaleProportionallyDown, forSegment: 0)
      setImageScaling(.scaleProportionallyDown, forSegment: 1)
      setWidth(frame.width - frame.height, forSegment: 0)
      setWidth(frame.height, forSegment: 1)

      proxy.observeRegistrationState { [weak self] in
        self?.updateVisualAppearance()
      }
      proxy.register()

      keyDownMonitor = EventMonitor(mask: .keyDown) { [weak self] event in
        guard let self = self else {
          return event
        }
        guard let key = KeyCommand.Key(Int(event.keyCode)) else {
          NSSound.beep()
          return nil
        }
        let modifiers = event.modifierFlags.swiftKeysModifiers
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
        guard !KeyCommand.isReservedBySystem(key: key, modifiers: modifiers) else {
          NSSound.beep()
          self.setFailureReason(.systemReserved(key: key, modifiers: modifiers))
          return nil
        }
        self.record(key: key, modifiers: modifiers)
        self.setFailureReason(.noFailure)
        return nil
      }
    }

    @objc
    func controlWasPressed(_ sender: KeyRecorderSegmentedControl) {
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
            proxy.removeKeyAndModifiers()
          } else {
            recordingState = .recording
          }
        }
      }
      updateBasedOnNewRecordingState()
    }

    func updateBasedOnNewRecordingState() {
      // Note: updateVisualAppearance() will get called as an observation
      // handler as soon as the proxy's registration state changes.
      switch recordingState {
      case .recording:
        proxy.unregister()
      case .idle:
        proxy.register()
        deselectAll()
      }
    }

    func record(key: KeyCommand.Key, modifiers: [KeyCommand.Modifier]) {
      proxy.withoutChangingRegistrationState {
        $0.key = key
        $0.modifiers = modifiers
      }
      proxy.register()
      recordingState = .idle
    }

    func updateVisualAppearance() {
      setLabel(forState: recordingState)
      setImage(forState: recordingState)
    }

    func setLabel(_ label: Label) {
      if let attributedLabel = attributedLabel {
        let image = NSImage(size: attributedLabel.size(), flipped: false) {
          attributedLabel.draw(in: $0)
          return true
        }
        setLabel("", forSegment: 0)
        setImage(image, forSegment: 0)
      } else if let label = self.label {
        setLabel(label, forSegment: 0)
        setImage(nil, forSegment: 0)
      } else {
        var string = ""
        if
          label == .hasKeyCommand,
          proxy.isRegistered,
          let key = proxy.key
        {
          string = proxy.modifiers.map { $0.stringValue }.joined()
          string.append(key.stringValue.uppercased(with: .current))
        } else {
          string = label.rawValue
        }
        setLabel(string, forSegment: 0)
        setImage(nil, forSegment: 0)
      }
    }

    func setLabel(forState state: RecordingState) {
      switch state {
      case .recording:
        setLabel(.typeShortcut)
      case .idle:
        if proxy.isRegistered {
          setLabel(.hasKeyCommand)
        } else {
          setLabel(.recordShortcut)
        }
      }
    }

    func setImage(forState state: RecordingState) {
      switch state {
      case .recording:
        setImage(escapeImage, forSegment: 1)
      case .idle:
        if proxy.isRegistered {
          setImage(deleteImage, forSegment: 1)
        } else {
          setImage(recordImage, forSegment: 1)
        }
      }
    }

    func deselectAll() {
      for n in 0..<segmentCount {
        setSelected(false, forSegment: n)
      }
    }

    func setFailureReason(_ failureReason: FailureReason) {
      if self.failureReason != failureReason {
        self.failureReason = failureReason
      }
    }

    func observeWindowVisibility() {
      windowVisibilityObservation = window?.observe(
        \.isVisible,
         options: .new
      ) { [weak self] _, change in
        guard
          let self = self,
          let newValue = change.newValue
        else {
          return
        }
        if !newValue {
          self.keyDownMonitor?.stop()
        }
      }
    }

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      updateVisualAppearance()
    }

    deinit {
      keyDownMonitor?.stop()
    }
  }
}

// MARK: - RecordingState

extension KeyRecorder.KeyRecorderSegmentedControl {
  enum RecordingState {
    case recording
    case idle
  }
}

// MARK: Label

extension KeyRecorder.KeyRecorderSegmentedControl {
  enum Label: String {
    case typeShortcut = "Type shortcut"
    case recordShortcut = "Record shortcut"
    case hasKeyCommand = "*****" // Should never be displayed
  }
}

// MARK: FailureReason

extension KeyRecorder.KeyRecorderSegmentedControl {
  struct FailureReason {
    let messageText: String
    let infoText: String

    var failureCount: Int {
      didSet {
        guard
          self == .noFailure,
          failureCount != 0
        else {
          return
        }
        failureCount = 0
      }
    }

    init(
      messageText: String = "Cannot record shortcut.",
      infoText: String,
      failureCount: Int = 0
    ) {
      self.messageText = messageText
      self.infoText = infoText
      self.failureCount = failureCount
    }

    mutating func incrementFailureCount() {
      failureCount += 1
    }

    func displayAlert() {
      guard self != .noFailure else {
        return
      }
      let alert = NSAlert()
      alert.messageText = messageText
      alert.informativeText = infoText
      alert.runModal()
    }
  }
}

extension KeyRecorder.KeyRecorderSegmentedControl.FailureReason {
  static let noFailure = Self(
    messageText: "",
    infoText: "No failure.")

  static let needsModifiers = Self(
    infoText: """
      Please include at least one modifier key \
      (\([KeyCommand.Modifier].canonicalOrder.stringValue)).
      """)

  static let onlyShift = Self(
    infoText: """
      Shift (\(KeyCommand.Modifier.shift.stringValue)) by itself is not a \
      valid modifier key. Please include at least one additional modifier \
      key (\([KeyCommand.Modifier].canonicalOrder.stringValue)).
      """)

  static func systemReserved(
    key: KeyCommand.Key,
    modifiers: [KeyCommand.Modifier]
  ) -> Self {
    let settingsString = ProcessInfo.processInfo.isOperatingSystemAtLeast(
      .init(
        majorVersion: 13,
        minorVersion: 0,
        patchVersion: 0))
    ? "Settings"
    : "Preferences"
    return .init(
      infoText: """
        "\(modifiers.stringValue)\(key.stringValue)" \
        is reserved system-wide. Most system shortcuts can be changed \
        from "System \(settingsString) › Keyboard › Keyboard Shortcuts".
        """,
      failureCount: 3)
  }
}

extension KeyRecorder.KeyRecorderSegmentedControl.FailureReason: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.messageText == rhs.messageText &&
    lhs.infoText == rhs.infoText
  }
}

// MARK: - NSEvent.ModifierFlags [extension]

extension NSEvent.ModifierFlags {
  var swiftKeysModifiers: [KeyCommand.Modifier] {
    .canonicalOrder.filter { contains($0.cocoaFlag) }
  }
}
