//===----------------------------------------------------------------------===//
//
// KeyRecorderView.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

#if canImport(SwiftUI)
import SwiftUI

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

/// A SwiftUI view that can record key events.
///
/// Start by creating a ``KeyEvent``. You can then use it to initialize a key
/// recorder view, which will update the event whenever a new key combination is
/// recorded. You can also observe the event, and perform actions on both
/// key-down and key-up.
///
/// ```swift
/// struct ContentView: View {
///     let event = KeyEvent(name: "SomeEvent")
///
///     var body: some View {
///         KeyRecorderView(keyEvent: event)
///     }
/// }
///
/// event.observe(.keyDown) {
///     print("DOWN")
/// }
/// event.observe(.keyUp) {
///     print("UP")
/// }
/// ```
@available(macOS 10.15, *)
public struct KeyRecorderView: View {
  /// Styles that affect the highlighted appearance of a key recorder view.
  public typealias HighlightStyle = KeyRecorder.HighlightStyle
  
  /// Styles that a key recorder view's bezel can be drawn in.
  public typealias BezelStyle = KeyRecorder.BezelStyle
  
  let keyEvent: KeyEvent
  
  public var body: some View {
    _KeyRecorderView {
      KeyRecorder(keyEvent: keyEvent)
    }
  }
  
  /// Creates a key recorder view for the given key event.
  public init(keyEvent: KeyEvent) {
    self.keyEvent = keyEvent
  }
  
  /// Creates a key recorder view for the key event with the given name.
  public init(name: KeyEvent.Name) {
    keyEvent = .init(name: name)
  }
}

@available(macOS 10.15, *)
private struct KeyRecorderHighlightStyleKey: EnvironmentKey {
  static var defaultValue = KeyRecorder.HighlightStyle.light
}

@available(macOS 10.15, *)
private struct KeyRecorderBezelStyleKey: EnvironmentKey {
  static var defaultValue = KeyRecorder.BezelStyle.rounded
}

@available(macOS 10.15, *)
private extension EnvironmentValues {
  var keyRecorderHighlightStyle: KeyRecorder.HighlightStyle {
    get { self[KeyRecorderHighlightStyleKey.self] }
    set { self[KeyRecorderHighlightStyleKey.self] = newValue }
  }
  
  var keyRecorderBezelStyle: KeyRecorder.BezelStyle {
    get { self[KeyRecorderBezelStyleKey.self] }
    set { self[KeyRecorderBezelStyleKey.self] = newValue }
  }
}

@available(macOS 10.15, *)
private struct KeyRecorderBezelStyle: ViewModifier {
  let bezelStyle: KeyRecorder.BezelStyle
  
  func body(content: Content) -> some View {
    content.environment(\.keyRecorderBezelStyle, bezelStyle)
  }
}

@available(macOS 10.15, *)
private struct KeyRecorderHighlightStyle: ViewModifier {
  let highlightStyle: KeyRecorder.HighlightStyle
  
  func body(content: Content) -> some View {
    content.environment(\.keyRecorderHighlightStyle, highlightStyle)
  }
}

@available(macOS 10.15, *)
extension View {
  /// Applies the given highlight style to a key recorder view.
  public func highlightStyle(_ style: KeyRecorderView.HighlightStyle) -> some View {
    modifier(KeyRecorderHighlightStyle(highlightStyle: style))
  }
  
  /// Applies the given bezel style to a key recorder view.
  public func bezelStyle(_ style: KeyRecorderView.BezelStyle) -> some View {
    modifier(KeyRecorderBezelStyle(bezelStyle: style))
  }
  
  /// Adds the given observation to the given key event, using the
  /// context of this view.
  ///
  /// This modifier is useful when working with bindings and state.
  /// Applying it in a custom view gives you access to that view's
  /// internal properties. If you don't need this access, you can
  /// simply call ``KeyEvent/observe(_:handler:)`` on an instance
  /// of ``KeyEvent``.
  ///
  /// The following example creates a custom view with a `Slider`
  /// subview and installs a key event observation that changes
  /// the custom view's `sliderValue` property. Since the property
  /// is bound to the value of the slider, whenever it updates,
  /// the slider's value does as well.
  ///
  /// ```swift
  /// struct ContentView: View {
  ///     @State var sliderValue = 0.5
  ///
  ///     let event = KeyEvent(name: "RandomizeSliderValue")
  ///
  ///     var body: some View {
  ///         Slider(value: $sliderValue)
  ///             .onKeyEvent(event, type: .keyDown) {
  ///                 sliderValue = .random(in: 0..<1)
  ///             }
  ///     }
  /// }
  /// ```
  ///
  /// - Note: The observation is not added until the view appears.
  public func onKeyEvent(
    _ keyEvent: KeyEvent,
    type: KeyEvent.EventType,
    perform handler: @escaping () -> Void
  ) -> some View {
    onAppear {
      keyEvent.observe(type, handler: handler)
    }
  }
  
  /// Adds the given observation to the key event with the given
  /// name, using the context of this view.
  ///
  /// This modifier is useful when working with bindings and state.
  /// Applying it in a custom view gives you access to that view's
  /// internal properties. If you don't need this access, you can
  /// simply call ``KeyEvent/observe(_:handler:)`` on an instance
  /// of ``KeyEvent``.
  ///
  /// The following example creates a custom view with a `Slider`
  /// subview and installs a key event observation that changes
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
  ///             .onKeyEvent(named: "RandomizeSliderValue", type: .keyDown) {
  ///                 sliderValue = .random(in: 0..<1)
  ///             }
  ///     }
  /// }
  /// ```
  ///
  /// - Note: The observation is not added until the view appears.
  public func onKeyEvent(
    named name: KeyEvent.Name,
    type: KeyEvent.EventType,
    perform handler: @escaping () -> Void
  ) -> some View {
    onKeyEvent(.init(name: name), type: type, perform: handler)
  }
}
#endif
