//===----------------------------------------------------------------------===//
//
// KeyRecorderView.swift
//
//===----------------------------------------------------------------------===//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - _KeyRecorderView

@available(macOS 10.15, *)
private struct _KeyRecorderView: NSViewRepresentable {
    let constructor: () -> KeyRecorder

    init(constructor: @escaping () -> KeyRecorder) {
        self.constructor = constructor
    }

    func makeNSView(context: Context) -> KeyRecorder {
        constructor()
    }

    func updateNSView(_ nsView: KeyRecorder, context: Context) {
        nsView.bezelStyle = context.environment.keyRecorderBezelStyle
    }
}

// MARK: - KeyRecorderView

/// A `SwiftUI` view that can record key commands.
///
/// Start by creating a ``KeyCommand``. You can then use it to initialize
/// a key recorder view, which will update the command whenever a new key
/// combination is recorded. You can also observe the command, and perform
/// actions on key-down, key-up, and double-tap.
///
/// ```swift
/// struct ContentView: View {
///     let command = KeyCommand(name: "someCommand")
///
///     var body: some View {
///         KeyRecorderView(command)
///             .onKeyCommand(type: .keyDown) {
///                 print("DOWN")
///             }
///             .onKeyCommand(type: .keyUp) {
///                 print("UP")
///             }
///             .onKeyCommand(type: .doubleTap(0.2)) {
///                 print("DOUBLE TAP")
///             }
///     }
/// }
/// ```
@available(macOS 10.15, *)
public struct KeyRecorderView: View {
    /// Styles that a key recorder view's bezel can be drawn in.
    public typealias BezelStyle = KeyRecorder.BezelStyle

    let keyCommand: KeyCommand

    var bodyConstructor: () -> AnyView

    public var body: some View {
        bodyConstructor()
    }

    private init(
        keyCommand: KeyCommand,
        @ViewBuilder bodyConstructor: @escaping () -> some View
    ) {
        self.keyCommand = keyCommand
        self.bodyConstructor = {
            AnyView(bodyConstructor())
        }
    }

    /// Creates a key recorder view for the given key command.
    public init(keyCommand: KeyCommand) {
        self.init(keyCommand: keyCommand) {
            _KeyRecorderView {
                KeyRecorder(keyCommand: keyCommand)
            }
        }
    }

    /// Creates a key recorder view for the given key command.
    public init(_ keyCommand: KeyCommand) {
        self.init(keyCommand: keyCommand)
    }

    /// Creates a key recorder view for the key command with the given name.
    public init(name: KeyCommand.Name) {
        self.init(keyCommand: .init(name: name))
    }

    func withBodyConstructor(
        @ViewBuilder bodyConstructor: @escaping () -> some View
    ) -> Self {
        var new = self
        new.bodyConstructor = {
            AnyView(bodyConstructor())
        }
        return new
    }

    /// Adds the given observation to the recorder view's key command.
    ///
    /// This modifier is useful when working with bindings and state.
    /// Applying it in a custom view gives you access to that view's
    /// internal properties. If you don't need this access, you can
    /// simply call ``KeyCommand/observe(_:handler:)`` on an instance
    /// of ``KeyCommand``.
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @AppStorage("muteSound") var muteSound = false
    ///
    ///     var body: some View {
    ///         VStack {
    ///             KeyRecorderView(name: .init("muteSound", prefix: "keyCommand"))
    ///                 .onKeyCommand(type: .keyDown) {
    ///                     muteSound.toggle()
    ///                 }
    ///             Toggle(isOn: $muteSound) {
    ///                 Text("Mute sound")
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Tip: Since this modifier returns another ``KeyRecorderView``,
    ///   you can chain it together with additional ``onKeyCommand(_:type:perform:)``
    ///   modifiers to add multiple observations.
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     let command = KeyCommand(name: "someCommand")
    ///
    ///     var body: some View {
    ///         KeyRecorderView(command)
    ///             .onKeyCommand(type: .keyDown) {
    ///                 print("DOWN")
    ///             }
    ///             .onKeyCommand(type: .keyUp) {
    ///                 print("UP")
    ///             }
    ///             .onKeyCommand(type: .doubleTap(0.2)) {
    ///                 print("DOUBLE TAP")
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: The observation is not added until the view appears.
    public func onKeyCommand(
        type: KeyCommand.EventType,
        perform handler: @escaping () -> Void
    ) -> Self {
        withBodyConstructor {
            onAppear {
                keyCommand.observe(type, handler: handler)
            }
        }
    }
}

// MARK: KeyRecorderView Deprecated
@available(macOS 10.15, *)
extension KeyRecorderView {
    @available(*, deprecated, renamed: "init(keyCommand:)")
    public init(command: KeyCommand) {
        self.init(keyCommand: command)
    }
}
#endif
