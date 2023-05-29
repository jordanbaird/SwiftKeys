//
// KeyRecorder.swift
// SwiftKeys
//

import AppKit

// MARK: - _KeyRecorderBaseControl

public class _KeyRecorderBaseControl: NSControl {
    let segmentedControl: KeyRecorderSegmentedControl

    var _bezelStyle: KeyRecorder.BezelStyle {
        didSet {
            _bezelStyle.apply(to: segmentedControl)
        }
    }

    init(_keyCommand: KeyCommand) {
        segmentedControl = KeyRecorderSegmentedControl(keyCommand: _keyCommand)
        _bezelStyle = KeyRecorder.BezelStyle(cocoaValue: segmentedControl.segmentStyle, default: .rounded)

        super.init(frame: segmentedControl.frame)

        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: segmentedControl.frame.width),
            heightAnchor.constraint(equalToConstant: segmentedControl.frame.height),
        ])

        addSubview(segmentedControl)
    }

    @available(*, unavailable)
    override init(frame frameRect: NSRect) {
        fatalError("init(frame:) is unavailable.")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("KeyRecorder must be created programmatically.")
    }
}

// MARK: - KeyRecorder

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
public final class KeyRecorder: _KeyRecorderBaseControl {
    /// A Boolean value that indicates whether the key recorder is
    /// drawn with a backing visual effect view.
    ///
    /// - Note: If ``bezelStyle-swift.property`` is ``BezelStyle-swift.enum/separated``,
    ///   this property is ignored.
    ///
    /// > Default value: `true`
    @available(*, deprecated, message: "Key recorders are no longer drawn with backing visual effect views.")
    public var hasBackingView = true {
        didSet {
            needsDisplay = true
        }
    }

    /// The style of the key recorder's bezel.
    /// > Default value: ``BezelStyle-swift.enum/rounded``
    public var bezelStyle: BezelStyle {
        get { _bezelStyle }
        set { _bezelStyle = newValue }
    }

    /// The key command associated with the recorder.
    public var keyCommand: KeyCommand {
        KeyCommand(name: segmentedControl.proxy.name)
    }

    /// The key command associated with the recorder.
    @available(*, deprecated, renamed: "keyCommand")
    public var command: KeyCommand { keyCommand }

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
        get { segmentedControl.attributedLabel ?? NSAttributedString(string: stringValue) }
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
    public init(keyCommand: KeyCommand) {
        super.init(_keyCommand: keyCommand)
    }

    /// Creates a key recorder for the given key command.
    ///
    /// Whenever a new key combination is recorded, the key and modifiers
    /// of the command will be updated to match.
    @available(*, deprecated, renamed: "init(keyCommand:)")
    public init(command: KeyCommand) {
        super.init(_keyCommand: command)
    }

    /// Creates a key recorder for the key command with the given name.
    ///
    /// If a command with the name does not exist, a blank command will be
    /// created. As soon as the key recorder records a key combination, the
    /// command will assume that combination's value.
    public convenience init(name: KeyCommand.Name) {
        self.init(keyCommand: KeyCommand(name: name))
    }
}

// MARK: - KeyRecorderSegmentedControl

class KeyRecorderSegmentedControl: NSSegmentedControl {

    // MARK: Properties

    var keyDownMonitor: EventMonitor?

    var mouseDownMonitor: EventMonitor?

    let proxy: KeyCommandProxy

    var observations = Set<NSKeyValueObservation>()

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

    var label: String? {
        didSet {
            updateVisualAppearance()
        }
    }

    var recordingState = RecordingState.idle {
        didSet {
            updateVisualAppearance()
            deselectAll()
            if recordingState == .recording {
                setSelected(true, forSegment: 0)
                failureReason = .noFailure
                keyDownMonitor?.start()
                mouseDownMonitor?.start()
                startObservations()
            } else if recordingState == .idle {
                keyDownMonitor?.stop()
                mouseDownMonitor?.stop()
                observations.removeAll()
            }
        }
    }

    var borderLayer: CALayer? {
        didSet {
            if let borderLayer {
                wantsLayer = true
                layer?.addSublayer(borderLayer)
            } else {
                oldValue?.removeFromSuperlayer()
            }
        }
    }

    var splitterLayer: CALayer? {
        didSet {
            if let splitterLayer {
                wantsLayer = true
                layer?.addSublayer(splitterLayer)
            } else {
                oldValue?.removeFromSuperlayer()
            }
        }
    }

    let deleteImage: NSImage = {
        // Force unwrap is okay here, as the image is an AppKit builtin.
        // swiftlint:disable:next force_unwrapping
        let image = NSImage(named: NSImage.stopProgressFreestandingTemplateName)!
        image.isTemplate = true
        return image
    }()

    let escapeImage: NSImage = {
        let escapeKeyCode = 0x238B
        let string = NSString(format: "%C", escapeKeyCode)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 16, weight: .thin),
        ]
        let stringSize = string.size(withAttributes: attributes)
        let image = NSImage(
            size: NSSize(width: stringSize.height, height: stringSize.height),
            flipped: false
        ) { bounds in
            let centeredRect = NSRect(
                origin: NSPoint(
                    x: bounds.midX - stringSize.width / 2,
                    y: bounds.midY - stringSize.height / 2
                ),
                size: stringSize
            )
            string.draw(in: centeredRect, withAttributes: attributes)
            return true
        }
        image.isTemplate = true
        return image
    }()

    let recordImage: NSImage = {
        let size = NSSize(width: 13, height: 13)
        let image = NSImage(size: size, flipped: false) { bounds in
            NSBezierPath(ovalIn: bounds.insetBy(dx: 2.5, dy: 2.5)).fill()
            NSBezierPath(ovalIn: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()
            return true
        }
        image.isTemplate = true
        return image
    }()

    var frameConvertedToWindow: NSRect {
        superview?.convert(frame, to: nil) ?? frame
    }

    // MARK: Initializers

    init(keyCommand: KeyCommand) {
        proxy = keyCommand.proxy
        super.init(frame: NSRect(origin: .zero, size: NSSize(width: 140, height: 24)))
        target = self
        action = #selector(controlWasPressed(_:))

        segmentCount = 2

        deselectAll()

        setImageScaling(.scaleProportionallyDown, forSegment: 0)
        setImageScaling(.scaleProportionallyDown, forSegment: 1)
        setWidth(frame.width - frame.height, forSegment: 0)
        setWidth(frame.height, forSegment: 1)

        proxy.observeRegistrationState { [weak self] in
            guard
                let self,
                !self.proxy.menuIsOpen
            else {
                return
            }
            self.updateVisualAppearance()
        }
        proxy.register()

        keyDownMonitor = EventMonitor(mask: .keyDown) { [weak self] event in
            guard let self else {
                return event
            }
            guard let key = KeyCommand.Key(rawValue: Int(event.keyCode)) else {
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

        mouseDownMonitor = EventMonitor(mask: .leftMouseDown) { [weak self] event in
            guard let self else {
                return event
            }
            if !self.frameConvertedToWindow.contains(event.locationInWindow) {
                self.recordingState = .idle
                self.updateBasedOnNewRecordingState()
            }
            return event
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("KeyRecorder must be created programmatically.")
    }

    // MARK: Methods

    @objc func controlWasPressed(_ sender: KeyRecorderSegmentedControl) {
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

    func deselectAll() {
        for n in 0..<segmentCount {
            setSelected(false, forSegment: n)
        }
    }

    func startObservations() {
        observations.removeAll()

        window?.observe(\.isVisible, options: .new) { [weak self] _, change in
            guard
                let self,
                let newValue = change.newValue
            else {
                return
            }
            if !newValue {
                self.recordingState = .idle
                self.updateBasedOnNewRecordingState()
            }
        }
        .store(in: &observations)

        NSWorkspace.shared.observe(\.frontmostApplication, options: .new) { [weak self] _, change in
            guard
                let self,
                let newValue = change.newValue
            else {
                return
            }
            if newValue != .current {
                self.recordingState = .idle
                self.updateBasedOnNewRecordingState()
            }
        }
        .store(in: &observations)
    }

    func record(key: KeyCommand.Key, modifiers: [KeyCommand.Modifier]) {
        proxy.withoutChangingRegistrationState { proxy in
            proxy.key = key
            proxy.modifiers = modifiers
        }
        proxy.register()
        recordingState = .idle
    }

    func setFailureReason(_ failureReason: FailureReason) {
        if self.failureReason != failureReason {
            self.failureReason = failureReason
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

    func setLabel(_ newLabel: Label) {
        if let attributedLabel {
            let image = NSImage(size: attributedLabel.size(), flipped: false) { bounds in
                attributedLabel.draw(in: bounds)
                return true
            }
            setLabel("", forSegment: 0)
            setImage(image, forSegment: 0)
        } else if let label {
            setLabel(label, forSegment: 0)
            setImage(nil, forSegment: 0)
        } else {
            let string: String
            if
                newLabel == .hasKeyCommand,
                proxy.isRegistered,
                let key = proxy.key
            {
                string = proxy.modifiers.stringValue + key.stringValue.localizedUppercase
            } else {
                string = newLabel.rawValue
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

    func updateVisualAppearance() {
        setLabel(forState: recordingState)
        setImage(forState: recordingState)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateVisualAppearance()
    }

    // MARK: Deinitializer

    deinit {
        keyDownMonitor?.stop()
        mouseDownMonitor?.stop()
    }
}

// MARK: - KeyRecorderSegmentedControl RecordingState

extension KeyRecorderSegmentedControl {
    enum RecordingState {
        case recording
        case idle
    }
}

// MARK: - KeyRecorderSegmentedControl Label

extension KeyRecorderSegmentedControl {
    enum Label: String {
        case typeShortcut = "Type shortcut"
        case recordShortcut = "Record shortcut"
        case hasKeyCommand = "*****" // Should never be displayed
    }
}

// MARK: - KeyRecorderSegmentedControl FailureReason

extension KeyRecorderSegmentedControl {
    struct FailureReason {
        let messageText: String
        let infoText: String

        var failureCount: Int {
            didSet {
                if self == .noFailure && failureCount != 0 {
                    failureCount = 0
                }
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

        func displayAlert() {
            guard self != .noFailure else {
                return
            }
            let alert = NSAlert()
            alert.messageText = messageText
            alert.informativeText = infoText
            alert.runModal()
        }

        mutating func incrementFailureCount() {
            failureCount += 1
        }
    }
}

// MARK: FailureReason Static Members
extension KeyRecorderSegmentedControl.FailureReason {
    static let noFailure = Self(
        messageText: "",
        infoText: "No failure."
    )

    static let needsModifiers = Self(
        infoText: """
            Please include at least one modifier key \
            (\([KeyCommand.Modifier].canonicalOrder.stringValue)).
            """
    )

    static let onlyShift = Self(
        infoText: """
            Shift (\(KeyCommand.Modifier.shift.stringValue)) by itself is not a \
            valid modifier key. Please include at least one additional modifier \
            key (\([KeyCommand.Modifier].canonicalOrder.stringValue)).
            """
    )

    static func systemReserved(key: KeyCommand.Key, modifiers: [KeyCommand.Modifier]) -> Self {
        let pathString: String = {
            let settingsOrPreferencesString: String
            if ProcessInfo.processInfo.isOperatingSystemAtLeast(
                OperatingSystemVersion(majorVersion: 13, minorVersion: 0, patchVersion: 0)
            ) {
                settingsOrPreferencesString = "Settings"
            } else {
                settingsOrPreferencesString = "Preferences"
            }
            return "System \(settingsOrPreferencesString) › Keyboard › Keyboard Shortcuts"
        }()
        return Self(
            infoText: """
                "\(modifiers.stringValue)\(key.stringValue)" is reserved system-wide. \
                Most system key commands can be changed in "\(pathString)".
                """,
            failureCount: 3
        )
    }
}

// MARK: FailureReason: Equatable
extension KeyRecorderSegmentedControl.FailureReason: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.messageText == rhs.messageText &&
        lhs.infoText == rhs.infoText
    }
}

// MARK: - ModifierFlags SwiftKeys Modifiers

extension NSEvent.ModifierFlags {
    var swiftKeysModifiers: [KeyCommand.Modifier] {
        .canonicalOrder.filter { contains($0.cocoaFlag) }
    }
}
