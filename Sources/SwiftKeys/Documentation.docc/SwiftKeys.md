# ``SwiftKeys``

A straightforward global key command API for macOS.

## Overview

`SwiftKeys` allows you to create, observe, and record global hotkeys.

### Creating and Observing

Start by creating an instance of ``KeyCommand``. Observe it, and perform actions on ``KeyCommand/EventType/keyDown``, ``KeyCommand/EventType/keyUp``, and ``KeyCommand/EventType/doubleTap(_:)``:

```swift
let command = KeyCommand(name: "ToggleMainWindow")

command.observe(.keyDown) {
    myCustomKeyDownAction()
}

command.observe(.keyUp) {
    myCustomKeyUpAction()
}

command.observe(.doubleTap(0.2)) {
    myCustomDoubleTapAction()
}
```

> ``KeyCommand/EventType/doubleTap(_:)`` allows you to specify a maximum time interval that the two key presses must fall within to be considered a "double-tap".

### Adding a Key Recorder

Use the key command's name to create a key recorder. Then, add it to a view (note the use of ``KeyRecorderView`` for SwiftUI and ``KeyRecorder`` for Cocoa):

#### SwiftUI

```swift
struct SettingsView: View {
    var body: some View {
        KeyRecorderView(name: "ToggleMainWindow")
    }
}
```

#### Cocoa

```swift
class SettingsViewController: NSViewController {
    let recorder = KeyRecorder(name: "ToggleMainWindow")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(recorder)
    }
}
```

The result should look something like this:

![](recorder-window)

The recorder and command will stay synchronized with each other, so when the user records a new key combination, the command will be updated to match the new value.

---

For improved type safety, you can create hard-coded command names that can be referenced across your app.

`Misc.swift`
```swift
extension KeyCommand.Name {
    static let toggleMainWindow = Self("ToggleMainWindow")
}
```

`AppDelegate.swift`
```swift
let command = KeyCommand(name: .toggleMainWindow)
```

`SettingsView.swift`
```swift
let recorder = KeyRecorder(name: .toggleMainWindow)
```

---

Key commands are automatically stored in the `UserDefaults` system, using their names as keys. It's common for `UserDefaults` keys to be prefixed, or namespaced, according to their corresponding app or subsystem. To that end, `SwiftKeys` lets you provide custom prefixes that can be applied to individual names.

```swift
extension KeyCommand.Name.Prefix {
    static let settings = Self("Settings")
    static let app = Self("MyGreatApp")
}

extension KeyCommand.Name {
    // "SettingsOpen" will be the full UserDefaults key.
    static let openSettings = Self("Open", prefix: .settings)

    // "MyGreatApp_Quit" will be the full UserDefaults key.
    static let quitApp = Self("Quit", prefix: .app, separator: "_")
}
```

You can find `SwiftKeys` [on GitHub](https://github.com/jordanbaird/SwiftKeys)

## Topics

### Essentials

- <doc:GettingStarted>
- ``KeyCommand``
- ``KeyRecorder``
- ``KeyRecorderView``
