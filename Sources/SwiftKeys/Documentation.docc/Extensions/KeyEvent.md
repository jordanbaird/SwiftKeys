# ``SwiftKeys/KeyEvent``

An observable key event.

## Overview

Create a key event by calling one of its initializers. You can then observe the event, and perform actions on both key-down and key-up.

```swift
let event = KeyEvent(name: "SomeEvent")

event.observe(.keyDown) {
    print("DOWN")
}
event.observe(.keyUp) {
    print("UP")
}
```

You can also initialize an event with a predefined key and modifiers. In the following example, the key event's observations will be triggered when the key combination "⇧⌥␣" (Shift-Option-Space) is pressed.

```swift
let event = KeyEvent(
    name: "SomeEvent",
    key: .space,
    modifiers: [.shift, .option])
```

If a key event is created with the same name as one that has been created previously, both events will now reference the same underlying object.

```swift
let originalEvent = KeyEvent(
    name: "SomeEvent",
    key: .space,
    modifiers: [.shift, .option])

let duplicateEvent = KeyEvent(name: "SomeEvent")

print(originalEvent == duplicateEvent)
// Prints: "true"

print(duplicateEvent.key)
// Prints: "space"

print(duplicateEvent.modifiers)
// Prints: "shift, option"
```

If the example above were to provide a new key and new modifiers in `duplicateEvent`'s initializer, both `duplicateEvent` _and_ `originalEvent` have those values.

```swift
let originalEvent = KeyEvent(
    name: "SomeEvent",
    key: .space,
    modifiers: [.shift, .option])

let duplicateEvent = KeyEvent(
    name: "SomeEvent",
    key: .leftArrow,
    modifiers: [.control, .command])

print(originalEvent == duplicateEvent)
// Prints: "true"

print(originalEvent.key)
// Prints: "leftArrow"

print(originalEvent.modifiers)
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
