# ``SwiftKeys``

A straightforward global hotkey API for macOS.

## Overview

`SwiftKeys` allows you to create, observe, and record global hotkeys in the form of the
``KeyEvent`` type.

Start by creating an instance of ``KeyEvent``. Then, use it to initialize a ``KeyRecorder`` 
instance. The recorder will stay synchronized with the key event, so that when it records a 
new key combination, the key event will update in accordance to the new value. You can also 
observe the event and perform actions on both key-down and key-up.

```swift
let event = KeyEvent(name: "SomeEvent")
let recorder = KeyRecorder(keyEvent: event)

event.observe(.keyDown) {
    print("DOWN")
}
event.observe(.keyUp) {
    print("UP")
}
```
For improved type safety, you can create hard-coded key event names that can be referenced 
across your app.

```swift
extension KeyEvent.Name {
    static let showPreferences = Self("ShowPreferences")
}
let event = KeyEvent(name: .showPreferences)
```

Key events are automatically stored `UserDefaults`. The name of the key event serves as
its key. You can provide a custom prefix that will be combined with each name to create 
the keys.

```swift
extension KeyEvent.Name.Prefix {
    public override var sharedPrefix: Self { 
        Self("SK") 
    }
}

extension KeyEvent.Name {
    static let showPreferences = Self("ShowPreferences")
}
// The name above will become "SKShowPreferences" when used as a defaults key.
```

You can find `SwiftKeys` [on GitHub](https://github.com/jordanbaird/SwiftKeys)

## Topics

### Creating and Observing Key Events

- ``KeyEvent``
- ``KeyEvent/Name-swift.struct``
- ``KeyEvent/Name-swift.struct/Prefix-swift.class``

### Recording Key Events

- ``KeyRecorder``
