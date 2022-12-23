# ``SwiftKeys``

A straightforward global key command API for macOS.

## Overview

`SwiftKeys` allows you to create, observe, and record global hotkeys.

Start by creating an instance of ``KeyCommand``. Then, use it to initialize a ``KeyRecorder`` instance. The key recorder's state is bound to the key command, so when it records a new key combination, the command will be updated. You can also observe the command and perform actions on both key-down and key-up.

```swift
let command = KeyCommand(name: "SomeCommand")
let recorder = KeyRecorder(keyCommand: command)

command.observe(.keyDown) {
    print("DOWN")
}
command.observe(.keyUp) {
    print("UP")
}
```

For improved type safety, you can create hard-coded key command names that can be referenced across your app.

```swift
extension KeyCommand.Name {
    static let showPreferences = Self("ShowPreferences")
}
let command = KeyCommand(name: .showPreferences)
```

Key commands are automatically stored `UserDefaults`. The name of the command serves as its key. You can provide a custom prefix that will be combined with each name to create the keys.

```swift
extension KeyCommand.Name.Prefix {
    public override var sharedPrefix: Self {
        Self("SK")
    }
}

extension KeyCommand.Name {
    static let showPreferences = Self("ShowPreferences")
}
// The name above will become "SKShowPreferences" when used as a defaults key.
```

You can find `SwiftKeys` [on GitHub](https://github.com/jordanbaird/SwiftKeys)

## Topics

### Essentials

- <doc:GettingStarted>
- ``KeyCommand``
- ``KeyRecorder``
- ``KeyRecorderView``
