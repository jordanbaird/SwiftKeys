# SwiftKeys

A Swifty API for global macOS hotkeys.

## Install

Add the following to your `Package.swift` file:

```swift
import PackageDescription

let package = Package(
    name: "PackageName",
    dependencies: [
        .package(url: "https://github.com/jordanbaird/SwiftKeys", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "PackageName",
            dependencies: ["SwiftKeys"]
        )
    ]
)
```

## Usage

Start by creating an instance of `KeyEvent` You then use it to initialize a `KeyRecorder` instance, 
which will update the event's value whenever a new key combination is recorded. You can also observe 
the event, and perform actions on both key-down and key-up.

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

Key events are automatically stored in the `UserDefaults` system, using their names as keys. You can provide
a custom prefix that will be combined with each name to create the keys.

```swift
extension KeyEvent.Name.Prefix {
    public override var sharedPrefix: Self { "SK" }
}
```

The `showPreferences` name from above would become "SKShowPreferences" when used as a `UserDefaults` key.

[Read full documentation here](https://jordanbaird.github.io/SwiftKeys/documentation/swiftkeys)
