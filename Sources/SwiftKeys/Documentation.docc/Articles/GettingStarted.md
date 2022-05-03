# Getting Started

Get to know the main types and methods of `SwiftKeys`. 

## Overview

There are two top-level types in this package: ``KeyEvent`` and ``KeyRecorder``. 

#### KeyEvent

``KeyEvent`` is quite powerful, yet simple to understand. To create one, all you need is a name, which will be used to store the event in `UserDefaults`.

```swift
let event = KeyEvent(name: "OpenPreferences")
```

When a `KeyEvent` is initialized, an internal reference is created with the name you provide. From this point forward, any event created with the same name will share the same reference -- and therefore, the same state. Let's create a new key event with the same name as before, but this time, we'll assign it a key and some modifiers.

```swift
let fullEvent = KeyEvent(
    name: "OpenPreferences", 
    key: .space, 
    modifiers: [.control, .shift])
```

Now, when we check the original event we created, we'll see that its values have changed.

```swift
let event = KeyEvent(name: "OpenPreferences")

print(event.key)
// Prints: "nil"

print(event.modifiers)
// Prints: "[]"

let fullEvent = KeyEvent(
    name: "OpenPreferences", 
    key: .space, 
    modifiers: [.control, .shift])

print(event.key)
// Prints: "space"

print(event.modifiers)
// Prints: "control, shift"
```

Every time a new event is created, the internal reference gets updated. This ensures that every name is associated with a consistent state, app-wide.

Now, let's call ``KeyEvent/observe(_:handler:)`` and give the event an action to perform when it receives a key-down message.

```swift
event.observe(.keyDown) {
    print("DOWN")
}
```

We can do the same for key-up.

```swift
event.observe(.keyDown) {
    print("DOWN")
}
event.observe(.keyUp) {
    print("UP")
}
```

- Tip: You can call ``KeyEvent/observe(_:handler:)`` as many times as you want.

Once an observation has been created, the event is enabled, and will start listening for its key combination. You can disable it by calling ``KeyEvent/disable()``, and re-enable it by calling ``KeyEvent/enable()``. If you need to remove the event entirely, you can do so by calling ``KeyEvent/remove()``.

In addition to operating on the key event itself, you can perform similar changes to its observations. When you call ``KeyEvent/observe(_:handler:)``, an instance of ``KeyEvent/Observation`` is returned, which contains the handler you provided. You can pass this into ``KeyEvent/removeObservation(_:)``, or another similar method to remove the observation from the event and stop the handler from being executed.

#### KeyRecorder

``KeyRecorder`` is a subclass of `NSControl` that enables you to record new keys and modifiers for a key event. Passing an event into ``KeyRecorder/init(keyEvent:)`` creates a key recorder whose state is bound to that event. You can also create a key recorder using ``KeyRecorder/init(name:)``, a convenience initializer which automatically creates a key event based on the name you provide.

![A window containing a KeyRecorder.](recorder_window.png)

Using a key recorder is extremely simple. Clicking inside puts it into "recording" mode, where it awaits a key-down message. As soon as a key combination is pressed, the recorder updates its key event and enters "idle" mode. In idle mode, a "clear" button appears, which resets the key event to an empty state.
