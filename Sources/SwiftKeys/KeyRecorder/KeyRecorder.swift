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
/// Start by creating a ``KeyEvent``. You can then use it to initialize a key
/// recorder, which will update the event whenever a new key combination is
/// recorded. You can also observe the event, and perform actions on both
/// key-down and key-up.
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
public final class KeyRecorder: NSControl {
  
  // MARK: - Instance Properties
  
  let segmentedControl: SegmentedControl
  
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
    if #available(macOS 10.11, *) {
      view.material = .sidebar
    } else {
      view.material = .titlebar
    }
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
  
  /// The key event associated with the recorder.
  public var keyEvent: KeyEvent {
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
  /// - Warning: Prior to macOS 10.13, the behavior of this property is undefined.
  public override var alignment: NSTextAlignment {
    get {
      if #available(macOS 10.13, *) {
        return segmentedControl.alignment(forSegment: 0)
      } else {
        return segmentedControl.alignment
      }
    }
    set {
      if #available(macOS 10.13, *) {
        segmentedControl.setAlignment(newValue, forSegment: 0)
      } else {
        segmentedControl.alignment = newValue
      }
    }
  }
  
  /// The appearance of the key recorder.
  public override var appearance: NSAppearance? {
    get { segmentedControl.appearance }
    set { segmentedControl.appearance = newValue }
  }
  
  // MARK: - Initializers
  
  /// Creates a key recorder for the given key event.
  ///
  /// Whenever the event records a key combination, the key and modifiers
  /// of the key recorder's event will be updated to match.
  public init(keyEvent: KeyEvent) {
    segmentedControl = .init(keyEvent: keyEvent)
    super.init(frame: segmentedControl.frame)
    Constraint(.width, of: self, constant: segmentedControl.frame.width).activate()
    Constraint(.height, of: self, constant: segmentedControl.frame.height).activate()
    addSubview(segmentedControl)
  }
  
  /// Creates a key recorder for the key event with the given name.
  ///
  /// If an event with the name does not exist, a blank event will be created.
  /// As soon as the key recorder records a key combination, the event will
  /// assume that combination's value.
  public convenience init(name: KeyEvent.Name) {
    self.init(keyEvent: .init(name: name))
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
    Constraint(.centerX, of: backingView, to: .centerX, of: self).activate()
    Constraint(.centerY, of: backingView, to: .centerY, of: self).activate()
    Constraint(.width, of: backingView, to: .width, of: self, constant: bezelStyle.widthConstant).activate()
    Constraint(.height, of: backingView, to: .height, of: self, constant: bezelStyle.heightConstant).activate()
  }
  
  private func removeBackingView() {
    backingView.removeFromSuperview()
  }
  
  private func addBorderView() {
    addSubview(borderView, positioned: .below, relativeTo: segmentedControl)
    Constraint(.centerX, of: borderView, to: .centerX, of: self).activate()
    Constraint(.centerY, of: borderView, to: .centerY, of: self).activate()
    Constraint(.width, of: borderView, to: .width, of: self, constant: bezelStyle.widthConstant).activate()
    Constraint(.height, of: borderView, to: .height, of: self, constant: bezelStyle.heightConstant).activate()
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
    Constraint(.centerX, of: highlightView, to: .centerX, of: self).activate()
    Constraint(.centerY, of: highlightView, to: .centerY, of: self).activate()
    Constraint(.width, of: highlightView, to: .width, of: self, constant: -4).activate()
    Constraint(.height, of: highlightView, to: .height, of: self, constant: -2).activate()
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

extension KeyRecorder {
  class SegmentedControl: NSSegmentedControl {
    let proxy: EventProxy
    
    var windowVisibilityObservation: NSKeyValueObservation?
    
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
          let alert = NSAlert()
          alert.messageText = failureReason.message
          alert.window.isMovable = false
          alert.runModal()
          self.failureReason = .noFailure
        }
      }
    }
    
    lazy var keyDownMonitor = EventMonitor(mask: .keyDown) { [weak self] event in
      guard let self = self else {
        return event
      }
      guard let key = KeyEvent.Key(Int(event.keyCode)) else {
        NSSound.beep()
        return nil
      }
      let modifiers = event.modifierFlags.keyEventModifiers
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
      guard !KeyEvent.isReservedBySystem(key: key, modifiers: modifiers) else {
        NSSound.beep()
        let alert = NSAlert()
        alert.window.isMovable = false
        alert.messageText = "Cannot record shortcut."
        alert.informativeText = "\""
        + modifiers.reduce("") { $0 + $1.stringValue }
        + key.stringValue
        + "\""
        + " is reserved system-wide."
        alert.runModal()
        return nil
      }
      self.record(key: key, modifiers: modifiers)
      self.setFailureReason(.noFailure)
      self.deselectAll()
      return nil
    }
    
    let imageDelete: NSImage = {
      let image = NSImage(named: NSImage.stopProgressFreestandingTemplateName)!
      image.isTemplate = true
      return image
    }()
    
    let imageEscape: NSImage = {
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
    
    var imageRecord: NSImage {
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
        if recordingState == .recording {
          deselectAll()
          setSelected(true, forSegment: 0)
          failureReason = .noFailure
          keyDownMonitor.start()
          observeWindowVisibility()
        } else if recordingState == .idle {
          keyDownMonitor.stop()
          windowVisibilityObservation = nil
        }
      }
    }
    
    init(keyEvent: KeyEvent) {
      proxy = keyEvent.proxy
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
      proxy.observeRegistrationState(updateVisualAppearance)
      proxy.register()
    }
    
    @objc
    func controlWasPressed(_ sender: SegmentedControl) {
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
    
    func record(key: KeyEvent.Key, modifiers: [KeyEvent.Modifier]) {
      proxy.mutateWithoutChangingRegistrationState {
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
        label == .keyEvent,
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
          setLabel(.keyEvent)
        } else {
          setLabel(.recordShortcut)
        }
      }
    }
    
    func setImage(forState state: RecordingState) {
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
          self.keyDownMonitor.stop()
        }
      }
    }
    
    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      updateVisualAppearance()
    }
    
    deinit {
      keyDownMonitor.stop()
    }
  }
}

extension KeyRecorder.SegmentedControl {
  enum RecordingState {
    case recording
    case idle
  }
  
  enum Label: String {
    case typeShortcut = "Type shortcut"
    case recordShortcut = "Record shortcut"
    case keyEvent = "*****"
  }
  
  struct FailureReason: Equatable {
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
        guard
          self == .noFailure,
          failureCount != 0
        else {
          return
        }
        failureCount = 0
      }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.message == rhs.message
    }
    
    mutating func incrementFailureCount() {
      failureCount += 1
    }
  }
}

extension NSEvent.ModifierFlags {
  var keyEventModifiers: [KeyEvent.Modifier] {
    var modifiers = [KeyEvent.Modifier]()
    // NOTE: Keep the order of these statements.
    if contains(.control) {
      modifiers.append(.control)
    }
    if contains(.option) {
      modifiers.append(.option)
    }
    if contains(.shift) {
      modifiers.append(.shift)
    }
    if contains(.command) {
      modifiers.append(.command)
    }
    return modifiers
  }
}
