# Getting Started

Get to know the main types and methods of `SwiftKeys`. 

## Overview

There are two top-level types in this package: ``KeyCommand`` and ``KeyRecorder``. 

#### KeyCommand

``KeyCommand`` is quite powerful, yet simple to understand. To create one, all you need is a name, which will be used to store the command in `UserDefaults`.

```swift
let command = KeyCommand(name: "OpenPreferences")
```

When a `KeyCommand` is initialized, an internal reference is created with the name you provide. From this point forward, any key command created with the same name will share the same reference -- and therefore, the same state. Let's create a new command with the same name as before, but this time, we'll assign it a key and some modifiers.

```swift
let fullCommand = KeyCommand(
    name: "OpenPreferences", 
    key: .space, 
    modifiers: [.control, .shift]
)
```

Now, when we check the original command we created, we'll see that its values have changed.

```swift
let command = KeyCommand(name: "OpenPreferences")

print(command.key)
// Prints: "nil"

print(command.modifiers)
// Prints: "[]"

let fullCommand = KeyCommand(
    name: "OpenPreferences", 
    key: .space, 
    modifiers: [.control, .shift]
)

print(command.key)
// Prints: "space"

print(command.modifiers)
// Prints: "control, shift"
```

Every time a new command is created, the internal reference gets updated. This ensures that every name is associated with a consistent state, app-wide.

Now, let's call ``KeyCommand/observe(_:handler:)`` and give the command an action to perform when it receives a key-down message.

```swift
command.observe(.keyDown) {
    print("DOWN")
}
```

We can do the same for key-up.

```swift
command.observe(.keyDown) {
    print("DOWN")
}
command.observe(.keyUp) {
    print("UP")
}
```

- Tip: You can call ``KeyCommand/observe(_:handler:)`` as many times as you want.

Once an observation has been created, the command is enabled, and will start listening for its key combination. You can disable it by calling ``KeyCommand/disable()``, and re-enable it by calling ``KeyCommand/enable()``. If you need to remove the command entirely, you can do so by calling ``KeyCommand/remove()``.

In addition to operating on the key command itself, you can perform similar changes to its observations. When you call ``KeyCommand/observe(_:handler:)``, an instance of ``KeyCommand/Observation`` is returned, which contains the handler you provided. You can pass this into ``KeyCommand/removeObservation(_:)``, or another similar method to remove the observation from the command and stop the handler from being executed.

#### KeyRecorder

``KeyRecorder`` is a subclass of `NSControl` that enables you to record new keys and modifiers for a key command. Passing a command into ``KeyRecorder/init(command:)`` creates a key recorder whose state is bound to that command. You can also create a key recorder using ``KeyRecorder/init(name:)``, a convenience initializer which automatically creates a key command based on the name you provide.

![A window containing a KeyRecorder.](recorder-window.png)

Using a key recorder is extremely simple. Clicking inside puts it into "recording" mode, where it awaits a key-down message. As soon as a key combination is pressed, the recorder updates its key command and enters "idle" mode. In idle mode, a "clear" button appears, which resets the key command to an empty state.
