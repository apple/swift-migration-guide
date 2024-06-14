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

### Ordered work processing in actors, when enqueueing from a synchronous contexts

Swift concurrency naturally enforces program order for asynchronous code as long 
as the execution remains in a single Task - this is equivalent to using "a single 
thread" to execute some work, but is more resource efficient because the task may 
suspend while waiting for some work, for example:

```
// ✅ Guaranteed order, since caller is a single task
let printer: Printer = ...
await printer.print(1)
await printer.print(2)
await printer.print(3)
```

This code is structurally guaranteed to execute the prints in the expected "1, 2, 3"
order, because the caller is a single task. Things 

Dispatch queues offered the common `queue.async { ... }` way to kick off some
asynchronous work without waiting for its result. In dispatch, if one were to 
write the following code:

```swift
let queue = DispatchSerialQueue(label: "queue")

queue.async { print(1) }
queue.async { print(2) }
queue.async { print(3) }
```

The order of the elements printed is guaranteed to be `1`, `2` and finally `3`.

At first, it may seem like `Task { ... }` is exactly the same, because it also 
kicks off some asynchronous computation without waiting for it to complete.
A naively port of the same code might look like this:

```swift
// ⚠️ any order of prints is expected
Task { print(1) }
Task { print(2) }
Task { print(3) }
```

This example **does not** guarantee anything about the order of the printed values,
because Tasks are enqueued on a global (concurrent) threadpool which uses multiple 
threads to schedule the tasks. Because of this, any of the tasks may be executed first.

Another attempt at recovering serial execution may be to use an actor, like this:

```swift
// ⚠️ still any order of prints is possible
actor Printer {}
    func go() {
        // Notice the tasks don't capture `self`!
        Task { print(1) }
        Task { print(2) }
        Task { print(3) }
    }
}
```

This specific example still does not even guarantee enqueue order (!) of the tasks,
and much less actual execution order. The tasks this is because lack of capturing 
`self` of the actor, those tasks are effectively going to run on the global concurrent 
pool, and not on the actor. This behavior may be unexpected, but it is the current semantics.

We can correct this a bit more in order to ensure the enqueue order, by isolating 
the tasks to the actor, this is done as soon as we capture the `self` of the actor:

```swift
// ✅ enqueue order of tasks is guaranteed
// 
// ⚠️ however. due to priority escalation, still any order of prints is possible (!) 
actor Printer {}
    func go() { // assume this method must be synchronous
        // Notice the tasks do capture self
        Task { self.log(1) }
        Task { self.log(2) }
        Task { self.log(3) }
    }
    
    func log(_ int: Int) { print(int) }
}
```

This improves the situation because the tasks are now isolated to the printer
instance actor (by means of using `Task{}` which inherits isolation, and refering 
to the actor's `self`), however their specific execution order is _still_ not deterministic.

Actors in Swift are **not** strictly FIFO ordered, and tasks
processed by an actor may be reordered by the runtime for example because 
of _priority escalation_. 

**Priority escalation** takes place when a low-priority task suddenly becomes
await-ed on by a high priority task. The Swift runtime is able to move such
task "in front of the queue" and effectively will process the now priority-escalated
task, before any other low-priority tasks. This effectively leads to FIFO order 
violations, because such task "jumped ahead" of other tasks which may have been 
enqueue on the actor well ahead of it. This does does help make actors very 
responsive to high priority work which is a valuable property to have!

> Note: Priority escalation is not supported on actors with custom executors.

The safest and correct way to enqueue a number of items to be processed by an actor,
in a specific order is to use an `AsyncStream` to form a single, well-ordered 
sequence of items, which can be emitted to even from synchronous code. 
And then consume it using a _single_ task running on the actor, like this:

```swift
// ✅ Guaranteed order in which log() are invoked,
//    regardless of priority escalations, because the disconnect 
//    between the producing and consuming task
actor Printer {
    let stream: AsyncStream<Int>
    let streamContinuation: AsyncStream<Int>.Continuation
    var streamConsumer: Task<Void, Never>!

    init() async {
        let (stream, continuation) = AsyncStream.makeStream(of: Int.self)
        self.stream = stream
        self.streamContinuation = continuation

        // Consuming Option A)
        // Start consuming immediately, 
        // or better have a caller of Printer call `startStreamConsumer()`
        // which would make it run on the caller's task, allowing for better use of structured concurrency.
        self.streamConsumer = Task { await self.consumeStream() }
    }

    deinit {
        self.streamContinuation.finish()
    }
  
    nonisolated func enqueue(_ item: Int) {
        self.streamContinuation.yield(item)
    }
  
    nonisolated func cancel() { 
      self.streamConsumer?.cancel()
    }

    func consumeStream() async {
        for await item in self.stream {
            if Task.isCancelled { break }
          
            log(item)
        }
    }

    func log(_ int: Int) { print(int) }
}
```

and invoke it like:

```
let printer: Printer = ... 
printer.enqueue(1)
printer.enqueue(2)
printer.enqueue(3)
```

We're assuming that the caller has to be in synchronous code, and this is why we make the `enqueue`
method `nonisolated` but we use it to funnel work items into the actor's stream.

The actor uses a single task to consume the async sequence of items, and this way guarantees
the specific order of items being handled.

This approach has both up and down-sides, because now the item processing cannot be affected by
priority escalation. The items will always be processed in their strict enqueue order,
and we cannot easily await for their results -- since the caller is in synchronous code,
so we might need to resort to callbacks if we needed to report completion of an item 
getting processed.

Notice that we kick off an unstructured task in the actor's initializer, to handle the 
consuming of the stream. This also may be sub-optimal, because as cancellation must 
now be handled manually. You may instead prefer to _not_ create the consumer task
at all in this Printer type, but require that some existing task invokes `await consumeStream()`, like this:

```
let printer: Printer = ...
Task { // or some structured task
  await printer.consumeStream() 
}
 
printer.enqueue(1)
printer.enqueue(2)
printer.enqueue(3)
```

In this case, you'd should make sure to only have at-most one task consuming the stream,
e.g. by using a boolean flag inside the printer actor.