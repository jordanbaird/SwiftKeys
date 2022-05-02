# SwiftKeys

![Continuous Integration](https://img.shields.io/circleci/build/github/jordanbaird/SwiftKeys/main)
![Release](https://img.shields.io/github/v/release/jordanbaird/SwiftKeys)
![Swift](https://img.shields.io/badge/dynamic/json?color=orange&label=Swift&query=Swift&suffix=%2B&url=https%3A%2F%2Fraw.githubusercontent.com%2Fjordanbaird%2FSwiftKeys%2Fmain%2Fswift-version)
![License](https://img.shields.io/github/license/jordanbaird/SwiftKeys)

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

Start by creating an instance of `KeyEvent`. Then, use it to initialize a `KeyRecorder` instance.
The recorder will stay synchronized with the key event, so that when it records a new key combination 
the key event will update in accordance to the new value. You can also observe the event and perform 
actions on both key-down and key-up.

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
