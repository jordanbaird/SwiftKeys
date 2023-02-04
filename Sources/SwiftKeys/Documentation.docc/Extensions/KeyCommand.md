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

You can also initialize a command with a predefined key and modifiers. In the following example, the command's observations will be triggered when the key combination "⌥⇧␣" (Option + Shift + Space) is pressed.

```swift
let command = KeyCommand(
    name: "SomeCommand",
    key: .space,
    modifiers: [.option, .shift]
)
```

If a key command is created with the same name as one that has been created previously, both commands will now reference the same underlying object.

```swift
let originalCommand = KeyCommand(
    name: "SomeCommand",
    key: .space,
    modifiers: [.option, .shift]
)

let duplicateCommand = KeyCommand(name: "SomeCommand")

print(originalCommand == duplicateCommand)
// Prints: "true"

print(duplicateCommand.key)
// Prints: "space"

print(duplicateCommand.modifiers)
// Prints: "option, shift"
```

If the example above were to provide a new key and new modifiers in `duplicateCommand`'s initializer, both `duplicateCommand` _and_ `originalCommand` have those values.

```swift
let originalCommand = KeyCommand(
    name: "SomeCommand",
    key: .space,
    modifiers: [.option, .shift]
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

- ``init(name:key:modifiers:)-7ly66``
- ``init(name:key:modifiers:)-41zy0``
- ``init(name:)``

### Observing

- ``name-swift.property``
- ``key-swift.property``
- ``modifiers``
- ``observe(_:handler:)``
- ``removeObservation(_:)``
- ``removeObservations(_:)``
- ``removeObservations(where:)``
- ``removeFirstObservation(where:)``
- ``removeAllObservations()``
- ``addObservation(_:)``

### Changing State

- ``enable()``
- ``disable()``
- ``remove()``
- ``isEnabled``
- ``disablesOnMenuOpen``

### Running a Key Command's Handlers

Sometimes, it's useful to be able to run the handlers stored under a key command without having to wait for it to trigger. You can do so using the following methods:

- ``runHandlers(for:)``
- ``runHandlers(where:)``

### Nested Types

- ``Observation``
- ``Name-swift.struct``
- ``Key-swift.enum``
- ``Modifier``
- ``EventType``
