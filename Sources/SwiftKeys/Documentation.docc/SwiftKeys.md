# ``SwiftKeys``

A straightforward global hotkey API for macOS.

## Overview

`SwiftKeys` allows you to create, observe, and record global hotkeys.

Start by creating an instance of ``KeyEvent``. Then, use it to initialize a ``KeyRecorder`` instance. The key recorder's state is bound to the key event, so when it records a new key combination, the key event will be updated. You can also observe the event and perform actions on both key-down and key-up.

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

For improved type safety, you can create hard-coded key event names that can be referenced across your app.

```swift
extension KeyEvent.Name {
    static let showPreferences = Self("ShowPreferences")
}
let event = KeyEvent(name: .showPreferences)
```

Key events are automatically stored `UserDefaults`. The name of the key event serves as its key. You can provide a custom prefix that will be combined with each name to create the keys.

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

### Essentials

- <doc:GettingStarted>
- ``KeyEvent``
- ``KeyRecorder``
- ``KeyRecorderView``
