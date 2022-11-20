# ``SwiftKeys/KeyCommand/Name-swift.struct/Prefix-swift.class``

A prefix that will be applied to a name when it is stored in `UserDefaults`.

## Overview

There are two different ways to initialize a prefix:

1. Using the standard initializer.
2. Using a string literal.

```swift
let prefix = KeyCommand.Name.Prefix("SomePrefix")
let prefix: KeyCommand.Name.Prefix = "SomePrefix"
```

This allows for a ``KeyCommand/Name-swift.struct`` instance to be initialized in the following ways:

```swift
// 1.
let prefix = KeyCommand.Name.Prefix("SomePrefix")
let name = KeyCommand.Name("SomeName", prefix: prefix)

// 2.
let name = KeyCommand.Name("SomeName", prefix: "SomePrefix")
```

### Creating a shared prefix

The `sharedPrefix` property serves as the defacto standard for prefixing all instances of ``KeyCommand/Name-swift.struct``. In order for a name to have a different prefix, it must be included in the name's initializer.

The default implementation of the property returns an instance containing an empty string. In essence, if you do nothing with this property, it will be as if it does not exist. If you choose to override this property, start by creating an extension to the ``Prefix-swift.class`` type. Once overridden, every instance of ``KeyCommand/Name-swift.struct`` will, by default, be saved to `UserDefaults` with the prefix you have chosen.

```swift
extension KeyCommand.Name.Prefix {
    public override var sharedPrefix: Self {
        Self("Watermelon")
    }
}
```

### Specializing a name with its own prefix

By default, ``KeyCommand/Name-swift.struct`` uses the `sharedPrefix` property. However, you can also choose to provide custom prefixes on an individual basis.

```swift
extension KeyCommand.Name.Prefix {
    static let skPrefix = Self("SK")
    static let jbPrefix = Self("JB")

    public override var sharedPrefix: Self {
        Self("Cheesecake")
    }
}

let quitApp = KeyCommand.Name("QuitApp", prefix: .skPrefix)
let makeSoup = KeyCommand.Name("MakeSoup", prefix: .jbPrefix)
let swimToSpain = KeyCommand.Name("SwimToSpain")

```

In the example above, "QuitApp" becomes "SKQuitApp" when used as a defaults key. "MakeSoup" becomes "JBMakeSoup". Since "SwimToSpain" did not provide a prefix, it gets assigned the shared prefix, and becomes "CheesecakeSwimToSpain".
