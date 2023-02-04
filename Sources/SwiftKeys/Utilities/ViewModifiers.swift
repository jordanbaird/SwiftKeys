//===----------------------------------------------------------------------===//
//
// ViewModifiers.swift
//
//===----------------------------------------------------------------------===//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - KeyRecorderBezelStyleKey

@available(macOS 10.15, *)
struct KeyRecorderBezelStyleKey: EnvironmentKey {
    static var defaultValue = KeyRecorderView.BezelStyle.rounded
}

// MARK: - EnvironmentValues

@available(macOS 10.15, *)
extension EnvironmentValues {
    var keyRecorderBezelStyle: KeyRecorderView.BezelStyle {
        get { self[KeyRecorderBezelStyleKey.self] }
        set { self[KeyRecorderBezelStyleKey.self] = newValue }
    }
}

// MARK: - KeyRecorderBezelStyle

@available(macOS 10.15, *)
struct KeyRecorderBezelStyle: ViewModifier {
    let bezelStyle: KeyRecorder.BezelStyle

    func body(content: Content) -> some View {
        content.environment(\.keyRecorderBezelStyle, bezelStyle)
    }
}

// MARK: - View Extension

@available(macOS 10.15, *)
extension View {
    /// Applies the given bezel style to a key recorder view.
    public func bezelStyle(_ style: KeyRecorderView.BezelStyle) -> some View {
        modifier(KeyRecorderBezelStyle(bezelStyle: style))
    }

    /// Adds the given observation to the given key command, using the
    /// context of this view.
    ///
    /// This modifier is useful when working with bindings and state.
    /// Applying it in a custom view gives you access to that view's
    /// internal properties. If you don't need this access, you can
    /// simply call ``KeyCommand/observe(_:handler:)`` on an instance
    /// of ``KeyCommand``.
    ///
    /// The following example creates a custom view with a `Slider`
    /// subview and installs a key command observation that changes
    /// the custom view's `sliderValue` property. Since the property
    /// is bound to the value of the slider, whenever it updates,
    /// the slider's value does as well.
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State var sliderValue = 0.5
    ///
    ///     let command = KeyCommand(name: "RandomizeSliderValue")
    ///
    ///     var body: some View {
    ///         Slider(value: $sliderValue)
    ///             .onKeyCommand(command, type: .keyDown) {
    ///                 sliderValue = .random(in: 0..<1)
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: The observation is not added until the view appears.
    public func onKeyCommand(
        _ keyCommand: KeyCommand,
        type: KeyCommand.EventType,
        perform handler: @escaping () -> Void
    ) -> some View {
        onAppear {
            keyCommand.observe(type, handler: handler)
        }
    }

    /// Adds the given observation to the key command with the given
    /// name, using the context of this view.
    ///
    /// This modifier is useful when working with bindings and state.
    /// Applying it in a custom view gives you access to that view's
    /// internal properties. If you don't need this access, you can
    /// simply call ``KeyCommand/observe(_:handler:)`` on an instance
    /// of ``KeyCommand``.
    ///
    /// The following example creates a custom view with a `Slider`
    /// subview and installs a key command observation that changes
    /// the custom view's `sliderValue` property. Since the property
    /// is bound to the value of the slider, whenever it updates,
    /// the slider's value does as well.
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State var sliderValue = 0.5
    ///
    ///     var body: some View {
    ///         Slider(value: $sliderValue)
    ///             .onKeyCommand(named: "RandomizeSliderValue", type: .keyDown) {
    ///                 sliderValue = .random(in: 0..<1)
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: The observation is not added until the view appears.
    public func onKeyCommand(
        named name: KeyCommand.Name,
        type: KeyCommand.EventType,
        perform handler: @escaping () -> Void
    ) -> some View {
        onKeyCommand(.init(name: name), type: type, perform: handler)
    }
}
#endif
