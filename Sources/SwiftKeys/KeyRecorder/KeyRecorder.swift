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
/// Start by creating a ``KeyCommand``. You can then use it to initialize a key
/// recorder, which will update the command whenever a new key combination is
/// recorded. You can also observe the command, and perform actions on both
/// key-down and key-up.
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
/// ```
public final class KeyRecorder: NSControl {
  
  // MARK: - Properties
  
  let segmentedControl: KeyRecorderSegmentedControl
  
  var cornerRadius: CGFloat {
    switch bezelStyle {
    case .rounded: return 5.5
    case .flatBordered: return 5.5
    case .separated: return 6
    case .square: return 0
    }
  }
  
  lazy var backingView: NSVisualEffectView = {
    let view = NSVisualEffectView(frame: frame)
    view.blendingMode = .behindWindow
    view.material = .sidebar
    view.wantsLayer = true
    view.layer?.cornerRadius = cornerRadius
    return view
  }()
  
  lazy var highlightView: NSVisualEffectView = {
    let view = NSVisualEffectView(frame: frame)
    view.blendingMode = .behindWindow
    view.wantsLayer = true
    view.layer?.cornerRadius = cornerRadius
    view.alphaValue = 0.75
    return view
  }()
  
  private var _borderViewPrototype: BorderView {
    .init(
      frame: frame,
      borderColor: .highlightColor,
      borderStyle: .solid,
      borderThickness: 1,
      cornerRadius: cornerRadius)
  }
  
  lazy var borderView: BorderView = _borderViewPrototype
  
  private var _hasBackingView = true
  
  /// A Boolean value that indicates whether the key recorder is
  /// drawn with a backing visual effect view.
  ///
  /// > Default value: `true`
  public var hasBackingView: Bool {
    get { _hasBackingView }
    set {
      _hasBackingView = newValue
      removeBackingView()
      if newValue {
        addBackingView()
      }
    }
  }
  
  @available(*, deprecated, renamed: "command")
  public var keyEvent: KeyEvent {
    .init(name: segmentedControl.proxy.name)
  }
  
  /// The key command associated with the recorder.
  public var command: KeyCommand {
    .init(name: segmentedControl.proxy.name)
  }
  
  /// A Boolean value that indicates whether the key recorder reacts
  /// to mouse events.
  public override var isEnabled: Bool {
    get { segmentedControl.isEnabled }
    set { segmentedControl.isEnabled = newValue }
  }
  
  private var _isHighlighted = false
  
  /// A Boolean value that indicates whether the key recorder is
  /// highlighted.
  ///
  /// Setting this value programmatically will immediately update
  /// the appearance of the key recorder.
  ///
  /// > Default value: `false`
  public override var isHighlighted: Bool {
    get { _isHighlighted }
    set {
      _isHighlighted = newValue
      removeHighlightView()
      if newValue {
        addHighlightView()
      }
    }
  }
  
  /// The appearance of the key recorder when it is highlighted.
  ///
  /// If the key recorder is already highlighted, and this value is set, the
  /// appearance will update in real time to match the new value.
  ///
  /// > Default value: ``HighlightStyle-swift.enum/light``
  public var highlightStyle = HighlightStyle.light {
    didSet {
      if isHighlighted {
        isHighlighted.toggle()
        isHighlighted.toggle()
      }
    }
  }
  
  private lazy var _bezelStyle = BezelStyle(segmentedControl.segmentStyle) {
    didSet { segmentedControl.segmentStyle = _bezelStyle.rawValue }
  }
  
  /// The style of the key recorder's bezel.
  ///
  /// Settings this value will immediately change bezel.
  /// > Default value: ``BezelStyle-swift.enum/rounded``
  public var bezelStyle: BezelStyle {
    get { _bezelStyle }
    set {
      _bezelStyle = newValue
      removeBackingView()
      if hasBackingView {
        addBackingView()
      }
      performCustomActions(for: newValue)
    }
  }
  
  /// The string value of the key recorder's label.
  ///
  /// Setting this value allows you to customize the text that is
  /// displayed to the user.
  public override var stringValue: String {
    get { segmentedControl.label(forSegment: 0) ?? attributedStringValue.string }
    set { segmentedControl.setLabel(newValue, forSegment: 0) }
  }
  
  /// The attributed string value of the key recorder's label.
  ///
  /// Setting this value allows you to customize the text that is
  /// displayed to the user.
  public override var attributedStringValue: NSAttributedString {
    get { segmentedControl.attributedLabel }
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
  
  // MARK: - Initializers
  
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
  
  private func addBackingView() {
    addSubview(backingView, positioned: .below, relativeTo: self)
    backingView.translatesAutoresizingMaskIntoConstraints = false
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
  
  private func removeBackingView() {
    backingView.removeFromSuperview()
  }
  
  private func addBorderView() {
    addSubview(borderView, positioned: .below, relativeTo: segmentedControl)
    borderView.translatesAutoresizingMaskIntoConstraints = false
    borderView.centerXAnchor.constraint(
      equalTo: centerXAnchor
    ).isActive = true
    borderView.centerYAnchor.constraint(
      equalTo: centerYAnchor
    ).isActive = true
    borderView.widthAnchor.constraint(
      equalTo: widthAnchor,
      constant: bezelStyle.widthConstant
    ).isActive = true
    borderView.heightAnchor.constraint(
      equalTo: heightAnchor,
      constant: bezelStyle.heightConstant
    ).isActive = true
  }
  
  private func removeAndResetBorderView() {
    borderView.removeFromSuperview()
    borderView = _borderViewPrototype
  }
  
  private func addHighlightView() {
    if hasBackingView {
      addSubview(highlightView, positioned: .above, relativeTo: backingView)
    } else {
      addSubview(highlightView, positioned: .below, relativeTo: self)
    }
    highlightView.material = highlightStyle.material
    highlightView.layer?.backgroundColor = highlightStyle.highlightColor.cgColor
    highlightView.translatesAutoresizingMaskIntoConstraints = false
    highlightView.centerXAnchor.constraint(
      equalTo: centerXAnchor
    ).isActive = true
    highlightView.centerYAnchor.constraint(
      equalTo: centerYAnchor
    ).isActive = true
    highlightView.widthAnchor.constraint(
      equalTo: widthAnchor,
      constant: -4
    ).isActive = true
    highlightView.heightAnchor.constraint(
      equalTo: heightAnchor,
      constant: -2
    ).isActive = true
  }
  
  private func removeHighlightView() {
    highlightView.removeFromSuperview()
  }
  
  private func performCustomActions(for style: BezelStyle) {
    removeAndResetBorderView()
    removeBackingView()
    removeHighlightView()
    
    if hasBackingView {
      addBackingView()
    }
    if isHighlighted {
      addHighlightView()
    }
    
    wantsLayer = true
    layer?.cornerRadius = cornerRadius
    backingView.layer?.cornerRadius = cornerRadius
    highlightView.layer?.cornerRadius = cornerRadius
    
    switch style {
    case .rounded, .flatBordered, .square:
      break
    case .separated(.solid):
      borderView.borderStyle = .solid
      addBorderView()
    case .separated(.dashed):
      borderView.borderStyle = .dashed
      addBorderView()
    case .separated(.noBorder):
      removeBackingView()
      removeHighlightView()
    }
  }
  
  /// Informs the view that it has been added to a new view hierarchy.
  ///
  /// If you override this method, you _must_ call `super` for the key
  /// recorder to maintain its correct behavior.
  public override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if hasBackingView {
      addBackingView()
    } else {
      removeBackingView()
    }
    if isHighlighted {
      addHighlightView()
    } else {
      removeHighlightView()
    }
  }
}

// MARK: - KeyRecorderSegmentedControl class

extension KeyRecorder {
  class KeyRecorderSegmentedControl: NSSegmentedControl {
    let proxy: Proxy
    
    var windowVisibilityObservation: NSKeyValueObservation?
    var keyDownMonitor: EventMonitor?
    
    var _attributedLabel: NSAttributedString?
    var attributedLabel: NSAttributedString {
      get {
        _attributedLabel ?? .init(string: label(forSegment: 0) ?? "")
      }
      set {
        _attributedLabel = newValue
        
        setLabel("", forSegment: 0)
        setImage(nil, forSegment: 0)
        
        let attStr = NSMutableAttributedString(attributedString: newValue)
        let fontSize = font?.pointSize ?? NSFont.systemFontSize
        
        for n in 0..<attStr.length {
          var attributes = attStr.attributes(at: n, effectiveRange: nil)
          if let font = attributes[.font] as? NSFont {
            attributes[.font] = NSFont(descriptor: font.fontDescriptor, size: fontSize)
          } else {
            attributes[.font] = self.font ?? NSFont.systemFont(ofSize: fontSize)
          }
          attStr.setAttributes(attributes, range: .init(location: n, length: 1))
        }
        
        let image = NSImage(size: attStr.size(), flipped: false) {
          attStr.draw(in: $0)
          return true
        }
        
        setImage(image, forSegment: 0)
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

// MARK: - RecordingState enum

extension KeyRecorder.KeyRecorderSegmentedControl {
  enum RecordingState {
    case recording
    case idle
  }
}

// MARK: Label enum

extension KeyRecorder.KeyRecorderSegmentedControl {
  enum Label: String {
    case typeShortcut = "Type shortcut"
    case recordShortcut = "Record shortcut"
    case hasKeyCommand = "*****" // Should never be displayed
  }
}

// MARK: FailureReason struct

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

// MARK: Predefined Failure Reasons

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

// MARK: - FailureReason: Equatable

extension KeyRecorder.KeyRecorderSegmentedControl.FailureReason: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.messageText == rhs.messageText &&
    lhs.infoText == rhs.infoText
  }
}

// MARK: - NSEvent.ModifierFlags extension

extension NSEvent.ModifierFlags {
  var swiftKeysModifiers: [KeyCommand.Modifier] {
    .canonicalOrder.filter { contains($0.cocoaFlag) }
  }
}
