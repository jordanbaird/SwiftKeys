# ``SwiftKeys/KeyCommand``

An observable key command.

## Overview

Create a key command by calling one of its initializers. You can then observe the command, and perform actions on both key-down and key-up.

```swift
let command = KeyCommand(name: "SomeCommand")

command.observe(.keyDown) {
    print("DOWN")
}
command.observe(.keyUp) {
    print("UP")
}
```

You can also initialize a command with a predefined key and modifiers. In the following example, the command's observations will be triggered when the key combination "⇧⌥␣" (Shift-Option-Space) is pressed.

```swift
let command = KeyCommand(
    name: "SomeCommand",
    key: .space,
    modifiers: [.shift, .option]
)
```

If a key command is created with the same name as one that has been created previously, both commands will now reference the same underlying object.

```swift
let originalCommand = KeyCommand(
    name: "SomeCommand",
    key: .space,
    modifiers: [.shift, .option]
)

let duplicateCommand = KeyCommand(name: "SomeCommand")

print(originalCommand == duplicateCommand)
// Prints: "true"

print(duplicateCommand.key)
// Prints: "space"

print(duplicateCommand.modifiers)
// Prints: "shift, option"
```

If the example above were to provide a new key and new modifiers in `duplicateCommand`'s initializer, both `duplicateCommand` _and_ `originalCommand` have those values.

```swift
let originalCommand = KeyCommand(
    name: "SomeCommand",
    key: .space,
    modifiers: [.shift, .option]
)

let duplicateCommand = KeyCommand(
    name: "SomeCommand",
    key: .leftArrow,
    modifiers: [.control, .command]
)

print(originalCommand == duplicateCommand)
// Prints: "true"

print(originalCommand.key)
// Prints: "leftArrow"

print(originalCommand.modifiers)
// Prints: "control, command"
```

## Topics

### Creating

- ``init(name:key:modifiers:)-5m38h``
- ``init(name:)``

### Observing

- ``Observation``
- ``EventType``
- ``observe(_:handler:)``
- ``removeObservation(_:)``
- ``removeObservations(_:)``
- ``removeObservations(where:)``
- ``removeAllObservations()``

### Changing State

- ``enable()``
- ``disable()``
- ``remove()``
- ``isEnabled``

### Naming and Prefixing

- ``name-swift.property``
- ``Name-swift.struct``
- ``Name-swift.struct/Prefix-swift.class``
