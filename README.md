<h1 align='center'>
    <br>
    <img src='Sources/SwiftKeys/Documentation.docc/Resources/header.png', style='width:67%'>
    <br>
    Global macOS key commands
    <br>
    <br>
</h1>

[![Continuous Integration][ci-badge]](https://github.com/jordanbaird/SwiftKeys/actions/workflows/test.yml)
[![Release][release-badge]](https://github.com/jordanbaird/SwiftKeys/releases/latest)
[![Swift Versions][versions-badge]](https://swiftpackageindex.com/jordanbaird/SwiftKeys)
[![Docs][docs-badge]](https://swiftpackageindex.com/jordanbaird/SwiftKeys/documentation)
[![License][license-badge]](LICENSE)

## Install

Add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/jordanbaird/SwiftKeys", from: "0.2.0")
```

## Usage

[Read the full documentation here](https://swiftpackageindex.com/jordanbaird/SwiftKeys/documentation)

### Creating and Observing

Start by creating an instance of `KeyCommand`. Observe it, and perform actions on `keyDown`, `keyUp`, and `doubleTap(_:)`:

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

> `doubleTap(_:)` allows you to specify a maximum time interval that the two key presses must fall within to be considered a "double-tap".

### Adding a Key Recorder

Use the key command's name to create a key recorder. Then, add it to a view (note the use of `KeyRecorderView` for SwiftUI and `KeyRecorder` for Cocoa):

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

| Light mode           | Dark mode                 |
| -------------------- | ------------------------- |
| ![][recorder-window] | ![][recorder-window~dark] |

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

Key commands are automatically stored in the `UserDefaults` system, using their names as keys. It's common for `UserDefaults` keys to be prefixed, or namespaced, according to their corresponding app or subsystem. To that end, SwiftKeys lets you provide custom prefixes that can be applied to individual names.

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

## License

SwiftKeys is available under the [MIT license](LICENSE).

[recorder-window]: Sources/SwiftKeys/Documentation.docc/Resources/recorder-window.png
[recorder-window~dark]: Sources/SwiftKeys/Documentation.docc/Resources/recorder-window~dark.png

[ci-badge]: https://img.shields.io/github/actions/workflow/status/jordanbaird/SwiftKeys/test.yml?branch=main&style=flat-square
[release-badge]: https://img.shields.io/github/v/release/jordanbaird/SwiftKeys?style=flat-square
[versions-badge]: https://img.shields.io/badge/dynamic/json?color=F05138&label=Swift&query=%24.message&url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fjordanbaird%2FSwiftKeys%2Fbadge%3Ftype%3Dswift-versions&style=flat-square
[docs-badge]: https://img.shields.io/static/v1?label=%20&message=documentation&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAEsSURBVHgB7dntDYIwEAbgV+MAuoEj6AaO4AiO4AayAbqBbuAGjoIbwAbnHT8MMTH9uEJrvCch/FB7vEh7EABjjBMRnXhrKY1GxsNUuFhN45gmBKU783lCDKtBiYeoUoeYI79KE6KEACI6RCkBRFSIkgKI4BClBRBBIUoMILxDlBpASIgjtBL3gR2FaV1jzjyKvg98xqDEw615t3Z87eFbc/IAPkJqljwHvFiA3CxAbhaAdI+cNZTUfWD4edQBOMacog9cEE/z25514twsQG4/H2ABJZ5vG97tEefKc/QJhRR9oIH7AeWbjodchdYcSnEJLRGvg5L6EmJb3g6Ic4eSNbLcLEBuf9HIZKnrl0rtvX8E5zLr8w+o79kVbkiBT/yZxn3Z90lqVTDGOL0AoGWIIaQgyakAAAAASUVORK5CYII=&color=informational&labelColor=gray&style=flat-square
[license-badge]: https://img.shields.io/github/license/jordanbaird/SwiftKeys?style=flat-square
