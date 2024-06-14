# Incremental Adoption

Learn how you can introduce Swift concurrency features into your project
incrementally.

Migrating projects towards the Swift 6 language mode is usually done in stages.
In fact, many projects began the process before Swift 6 was even available.
You can continue to introduce concurrency features _gradually_,
addressing any problems that come up along the way.
This allows you to make incremental progress without disrupting the
entire project.

Swift includes a number of language features and standard library APIs to help
make incremental adoption easier.

## Wrapping Callback-Based Functions

APIs that accept and invoke a single function on completion are an extremely
common pattern in Swift.
It's possible to make a version of such a function that is usable directly from 
an asynchronous context.

```swift
func updateStyle(backgroundColor: ColorComponents, completionHandler: @escaping () -> Void) {
    // ...
}
```

This is an example of a function that informs a client its work is complete
using a callback.
There is no way for a caller to determine when or on what thread the callback
will be invoked without consulting documentation.

You can wrap this function up into an asynchronous version using
_continuations_.

```swift
func updateStyle(backgroundColor: ColorComponents) async {
    withCheckedContinuation { continuation in
        updateStyle(backgroundColor: backgroundColor) {
            continuation.resume()
        }
    }
}
```

With an asynchronous version, there is no longer any ambiguity.
After the function has completed, execution will always resume in the same
context it was started in.

```swift
await updateStyle(backgroundColor: color)
// style has been updated
```

The `withCheckedContinuation` function is one of a [suite of standard library
APIs][continuation-apis] that exist to make interfacing non-async and async code possible.

> Note: Introducing asynchronous code into a project can surface data isolation
checking violations. To understand and address these, see [Crossing Isolation Boundaries][]

[Crossing Isolation Boundaries]: commonproblems#Crossing-Isolation-Boundaries
[continuation-apis]: https://developer.apple.com/documentation/swift/concurrency#continuations

## Dynamic Isolation

Expressing the isolation of your program statically, using annotations and
other language constructs, is both powerful and concise.
But, it can be difficult to introduce static isolation without updating
all dependencies simultaneously.

Dynamic isolation provides runtime mechanisms you can use as a fallback for
describing data isolation.
It can be an essential tool for interfacing a Swift 6 component
with another that has not yet been updated,
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
adding static isolation here could require many additional changes.
An alternative is to use dynamic isolation to help control the scope.

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
This keeps any changes localized to the type, allowing you make
changes without affecting any clients of the type.

However, a major disadvantage of this technique is the type's true isolation
requirements remain invisible.
There is no way for clients to determine if or how they should change based on
this public API.
You should use this approach only as a temporary solution, and only when you
have exhausted other options.

### Usage-Only Isolation

If it is impractical to contain isolation exclusively within a type, you can
instead expand the isolation to cover only its API usage.

To do this, first apply static isolation to the type,
and then use dynamic isolation at any usage locations:

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

Combining static and dynamic isolation can be a powerful tool to keep the
scope of changes gradual.

## Backwards Compatibility

It's important to keep in mind that static isolation, being part of the type
system, affects your public API.
But, you can migrate your own modules in a way that improves their APIs for
Swift 6 *without* breaking any existing clients.

Suppose the `WindowStyler` is public API.
You have determined that it really should be `MainActor`-isolated, but want to
ensure backwards compatibility for clients.

```swift
@preconcurrency @MainActor
public class WindowStyler {
    // ...
}
```

Using `@preconcurrency` this way marks the isolation as conditional on the
client module also having complete checking enabled.
This preserves source compatibility with clients that have not yet begun
adopting Swift 6.

## Dependencies

Often, you aren't in control of the modules you need to import as dependencies.
If these modules have not yet adopted Swift 6, you may find yourself with
errors that are difficult or impossible to resolve.

There are a number of different kinds of problems that result from using
unmigrated code.
The `@preconcurrency` annotation can help with many of these situations:

- [Non-Sendable types][]
- Mismatches in [protocol-conformance isolation][]

[Non-Sendable types]: commonproblems#Crossing-Isolation-Boundaries
[protocol-conformance isolation]: commonproblems#Crossing-Isolation-Boundaries

## C/Objective-C

You can expose Swift concurrency support for your C and Objective-C APIs
using annotations.
This is made possible by Clang's
[concurrency-specific annotations][clang-annotations]:

[clang-annotations]: https://clang.llvm.org/docs/AttributeReference.html#customizing-swift-import

```
__attribute__((swift_attr(“@Sendable”)))
__attribute__((swift_attr(“@_nonSendable”)))
__attribute__((swift_attr("nonisolated")))
__attribute__((swift_attr("@UIActor")))

__attribute__((swift_async(none)))
__attribute__((swift_async(not_swift_private, COMPLETION_BLOCK_INDEX))
__attribute__((swift_async(swift_private, COMPLETION_BLOCK_INDEX)))
__attribute__((__swift_async_name__(NAME)))
__attribute__((swift_async_error(none)))
__attribute__((__swift_attr__("@_unavailableFromAsync(message: \"" msg "\")")))
```

When working with a project that can import Foundation, the following
annotation macros are available in `NSObjCRuntime.h`:

```
NS_SWIFT_SENDABLE
NS_SWIFT_NONSENDABLE
NS_SWIFT_NONISOLATED
NS_SWIFT_UI_ACTOR

NS_SWIFT_DISABLE_ASYNC
NS_SWIFT_ASYNC(COMPLETION_BLOCK_INDEX)
NS_REFINED_FOR_SWIFT_ASYNC(COMPLETION_BLOCK_INDEX)
NS_SWIFT_ASYNC_NAME
NS_SWIFT_ASYNC_NOTHROW
NS_SWIFT_UNAVAILABLE_FROM_ASYNC(msg)
```
## Dispatch

Some patterns which you may be used to from Dispatch or other concurrency libraries
may need to be re-shaped in order to fit the world of Swift's structured concurrency model. 

### Limiting concurrency using Task Groups

Sometimes you may find yourself with a large list of work to be processed.

While it is possible to just enqueue "all" those work items to a task group like this:

```swift
// WARNING: Potentially wasteful -- perhaps this creates thousands of tasks concurrently (?!)

let lotsOfWork: [Work] = ...
await withTaskGroup(of: Something.self) { group in
  for work in lotsOfWork {
    // WARNING: If this is thousands of items, we may end up creating a lot of tasks
    //  which won't get to be executed until much later, as we have a global limit on
    //  the amount of concurrently running tasks - depending on the core count of the system,
    //  and the default global executor's configuration.
    group.addTask {
      await work.work()
    }
  }

  for await result in group {
    process(result) // process the result somehow, depends on your needs
  }
}
```

If you suspect you may be dealing with hundreds or thousands of items, it may be wasteful to enqueue them all immediately.
Creating a task (in `addTask`) needs to allocate some memory for the task in order to suspend and execute,
while this amount of memory isn't too large, it can become significant if creating thousands of tasks which don't get to
execute immediately but are just waiting until the executor gets to run them.

When faced with such a situation, it may be beneficial to manually throttle the number of concurrently added tasks to the task group, as follows:

```swift
let lotsOfWork: [Work] = ... 
let maxConcurrentWorkTasks = min(lotsOfWork.count, 10)
assert(maxConcurrentWorkTasks > 0)

await withTaskGroup(of: Something.self) { group in
    var submittedWork = 0
    for _ in 0..<maxConcurrentWorkTasks {
        group.addTask { // or 'addTaskUnlessCancelled'
            await lotsOfWork[submittedWork].work() 
        }
        submittedWork += 1
    }
    
    for await result in group {
        process(result) // process the result somehow, depends on your needs
    
        // Every time we get a result back, check if there's more work we should submit and do so
        if submittedWork < lotsOfWork.count, 
           let remainingWorkItem = lotsOfWork[submittedWork] {
            group.addTask { // or 'addTaskUnlessCancelled'
                await remainingWorkItem.work() 
            }  
            submittedWork += 1
        }
    }
}
```
