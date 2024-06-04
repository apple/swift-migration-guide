# Incremental Adoption

Learn how you can introduce Swift currency features into your project
incrementally.

The Swift 6 language mode must be explicitly enabled for existing projects.
But, enabling the mode is just the first part of the process.
You'll probably want to progress by making incremental changes that do not
disrupt project.

Swift includes a number of language features and standard libary APIs to help
make this process easier.

## Wrapping Callback-Based Functions

APIs that accept and invoke a single function on completion are an extremely
common pattern in Swift.
It's possible to make version of such a function that is usable directly from 
an asynchronous context.

```swift
func updateStyle(backgroundColor: ColorComponents, completionHandler: @escaping () -> Void) {
    // ...
}
```

This is an example of a function that informs a client its work is complete
using a callback.
You can wrap this function up into an asynchronous version using continuations.

```swift
func updateStyle(backgroundColor: ColorComponents) async {
    withCheckedContinuation { continuation in
        updateStyle(backgroundColor: backgroundColor) {
            continuation.resume()
        }
    }
}
```

With `withCheckedContinuation` is one of a suite of standard library APIs that
exist to make interfacing non-async and async code possible.

> Note: Introducing asynchronous code into a project can surface data isolation
checking violations. To understand and address these, see [Crossing Isolation Boundaries][]

[Crossing Isolation Boundaries]: commonproblems#Crossing-Isolation-Boundaries

## Dynamic Isolation

Expressing the isolation of your program statically, using annotations and
other language constructs, is a powerful way to ensure data race safety.
But, because static isolation uses Swift's type system, it can potentially
require changes all places a type or function is used.

Dynamic isolation provides runtime mechanisms for expressing data isolation.
These are much more manual, but provide a flexible alternative.
This can be an essential tool for interfacing a Swift 6 component with another
that has not yet migrated,
even if these components are within the _same_ module.

### Internal-Only Isolation

Suppose you have determined that a reference type within your project can be
best described with `MainActor` static isolation.

```swift
@MainActor
class WindowStyler {
    private var backgroundColor: ColorComponents

    func applyStyle() {
        // ...
    }
}
```

This `MainActor` isolation may be _logically_ correct.
But, if this type is used in other unmigrated locations,
introducing static isolation here could require many additional changes.
An alternative is to use dynamic isolation to help control the scope of the
required changes.

```swift
class WindowStyler {
    @MainActor
    private var backgroundColor: ColorComponents

    func applyStyle() {
        MainActor.assumeIsolated {
            // use and interact with other `MainActor` state
        }
    }
}
```

Here, the isolation has been internalized into the class.
This keeps any changes localized to the type, allowing you make any
internal changes needed without affecting any clients of the type.
A disadvantage of this technique is method arguments and return values might
now need to cross otherwise-unnecessary isolation boundaries.

### Usage-Only Isolation

If it is impractical to contain isolation exclusively within a type, you can
instead expand the isolation to cover only its API usage.

In this case, you can first apply static isolation to the type, and then use
dynamic isolation at any usage locations:

```swift
@MainActor
class WindowStyler {
    // ...
}

class UIStyler {
    @MainActor
    private let windowStyler: WindowStyler
    
    func applyStyle() {
        MainActor.assumeIsolated {
            windowStyler.applyStyle()
        }
    }
}
```

A variant of this technique can also work in an asynchronous context.
This is particularly helpful when you have a class that already has
`async` methods, but hasn't yet established correct static isolation.

```swift
@MainActor
class WindowStyler {
    // ...
}

class UIStyler {
    @MainActor
    private let windowStyler = WindowStyler()

    func updateStyle() async {
        await MainActor.run {
            windowStyler.applyStyle()
        }
    }
}
```

Combining static and dynamic isolation can be a powerful tool to keep the
scope of changes gradual.

## Backwards Compatibility

It's important to keep in mind that static isolation, being part of the type
system, affects your public API.
You can migrate your own modules in a way that improves their APIs for Swift 6
without breaking any existing clients.

Suppose the `WindowStyler` is public API.
You have determined that it really should be MainActor-isolated, but want to
ensure backwards compatibility for clients.

```swift
@preconcurrency @MainActor
public class WindowStyler {
    // ...
}
```

Using `@preconcurrency` this way marks the isolation as conditional on the
client module also having complete checking enabled.

## Dependencies

Often, you aren't in control of the modules you need to import as dependencies.
If these modules have not yet adopted Swift 6, you may find yourself with
errors that are difficult or impossible to resolve.

There are a number of different kinds of problems that result from using
unmigrated code.

Situations where `@preconcurrency` can help include:

- [Non-Sendable types][]
- Mismatches in [protocol-conformance isolation][]

[Non-Sendable types]: 

> Note: For more information, see [Crossing Isolation Boundaries][]

[Crossing Isolation Boundaries]: commonproblems#Crossing-Isolation-Boundaries

An import annotated with `@preconcurrency` can downgrade diagnostics related
to non-Sendable types within the module.

It can downgrade isolation boundary checking problems, resolve

### Pre-Swift 6

### C/Objective-C

