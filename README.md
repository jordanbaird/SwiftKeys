<div align='center'>
    <img src='/media/header.svg'>
    <h2>A Swifty API for global macOS hotkeys.</h2>
    <br/>
</div>

![Continuous Integration](https://img.shields.io/circleci/build/github/jordanbaird/SwiftKeys/main)
[![Code Coverage](https://codecov.io/gh/jordanbaird/SwiftKeys/branch/main/graph/badge.svg?token=PARNSVMN0H)](https://codecov.io/gh/jordanbaird/SwiftKeys)
![Release](https://img.shields.io/github/v/release/jordanbaird/SwiftKeys)
![Swift Version](https://img.shields.io/badge/Swift-5.6%2B-orange)
![License](https://img.shields.io/github/license/jordanbaird/SwiftKeys)

## Install

Add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/jordanbaird/SwiftKeys", from: "0.0.7")
```

## Usage

[Read the full documentation here](https://jordanbaird.github.io/SwiftKeys/documentation/swiftkeys)

Start by creating an instance of `KeyEvent`. Then, use it to initialize a `KeyRecorder`.

```swift
let event = KeyEvent(name: "SomeEvent")
let recorder = KeyRecorder(keyEvent: event)
```

<div align='center'>
    <img src='docs/images/recorder-window.png', style='width:49%'>
    <img src='docs/images/recorder-window~dark.png', style='width:49%'>
</div>

The recorder and the event will stay synchronized with each other, so when the user records a new key combination, the event will update to the new value. You can also observe the event and perform actions on both key-up and key-down.

```swift
event.observe(.keyUp) {
    print("UP")
}
event.observe(.keyDown) {
    print("DOWN")
}
```

For improved type safety, you can create hard-coded key event names that can be referenced across your app.

```swift
extension KeyEvent.Name {
    static let showPreferences = Self("ShowPreferences")
}
let event = KeyEvent(name: .showPreferences)
```

Key events are automatically stored in the `UserDefaults` system, using their names as keys. You can provide a custom prefix that will be combined with each name to create the keys.

```swift
extension KeyEvent.Name.Prefix {
    public override var sharedPrefix: Self { 
        Self("SK")
    }
}
```

In the example above, the name "ShowPreferences" would become "SKShowPreferences" when used as a defaults key.

The following pseudo-code is what a typical view controller that utilizes `SwiftKeys` might look like:

```swift
import SwiftKeys

class ViewController: NSViewController {
    let event = KeyEvent(name: "SomeEvent")
    let recorder = KeyRecorder(keyEvent: event)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(recorder)
        
        event.observe(.keyUp) {
            print("UP")
        }
        event.observe(.keyDown) {
            print("DOWN")
        }
    }
}
```

## License

SwiftKeys is licensed under the [MIT license](http://www.opensource.org/licenses/mit-license).
