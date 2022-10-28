<h1 align='center'>
    <br>
    <img src='/media/header.png', style='width:60%'>
    <br>
    Global macOS key commands
    <br>
    <br>
</h1>

![Continuous Integration](https://img.shields.io/github/workflow/status/jordanbaird/SwiftKeys/Continuous%20Integration?style=flat-square)
[![Code Coverage](https://img.shields.io/codecov/c/github/jordanbaird/SwiftKeys?label=codecov&logo=codecov&style=flat-square)](https://codecov.io/gh/jordanbaird/SwiftKeys)
![Release](https://img.shields.io/github/v/release/jordanbaird/SwiftKeys?style=flat-square)
[![Swift Versions](https://img.shields.io/badge/dynamic/json?color=F05138&label=Swift&query=%24.message&url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fjordanbaird%2FSwiftKeys%2Fbadge%3Ftype%3Dswift-versions&style=flat-square)](https://swiftpackageindex.com/jordanbaird/SwiftKeys)
![License](https://img.shields.io/github/license/jordanbaird/SwiftKeys?style=flat-square)

## Install

Add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/jordanbaird/SwiftKeys", from: "0.1.0")
```

## Usage

[Read the full documentation here](https://swiftpackageindex.com/jordanbaird/SwiftKeys/documentation)

Start by creating an instance of `KeyCommand`.

Observe it and perform actions on `keyDown`, `keyUp`, or both:

```swift
let command = KeyCommand(name: "ToggleMainWindow")

command.observe(.keyDown) {
    if mainWindow.isVisible {
        mainWindow.orderOut(command)
    } else {
        mainWindow.makeKeyAndOrderFront(command)
    }
}

command.observe(.keyUp) {
    if Int.random(in: 0..<10) == 7 {
        performJumpScare()
    }
}
```

Use the key command's name to create a key recorder. Then, add it to a view (note the use of `KeyRecorderView` for SwiftUI and `KeyRecorder` for Cocoa):

### SwiftUI

```swift
struct SettingsView: View {
    var body: some View {
        KeyRecorderView(name: "ToggleMainWindow")
    }
}
```

### Cocoa

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

| Light mode | Dark mode |
| ---------- | --------- |
| ![][light] | ![][dark] |

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

Key commands are automatically stored in the `UserDefaults` system, using their names as keys. It's common for `UserDefaults` keys to be prefixed, or namespaced, according to their corresponding app or subsystem. To that end, SwiftKeys lets you provide custom prefixes that can be applied to individual names, as well as a global, shared prefix that will automatically apply to every name that doesn't explicitly specify otherwise.

```swift
extension KeyCommand.Name.Prefix {
    public override var sharedPrefix: Self { 
        Self("MyApp")
    }
}
```

In the example above, the name "ToggleMainWindow" would become "MyAppToggleMainWindow" when used as a `UserDefaults` key.

## License

SwiftKeys is licensed under the [MIT license](http://www.opensource.org/licenses/mit-license).

[light]: Sources/SwiftKeys/Documentation.docc/Resources/recorder-window.png
[dark]: Sources/SwiftKeys/Documentation.docc/Resources/recorder-window~dark.png
