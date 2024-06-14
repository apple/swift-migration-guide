# Runtime Behavior


Learn how Swift concurrency runtime semantics differ from other runtimes you may 
be familiar with, and familiarize yourself with common patterns to achieve 
similar end results in terms of execution semantics.

Swift's concurrency model with a strong focus on async/await, actors and tasks,
means that some patterns from other libraries or concurrency runtimes don't 
translate directly into this new model. In this section, we'll explore common 
patterns and differences in runtime behavior to be aware of, and how to address 
them while you migrate your code to Swift concurrency.

## Ordered Processing

### Ordered work processing in actors, when enqueueing from a synchronous contexts

Swift concurrency naturally enforces program order for asynchronous code as long
as the execution remains in a single Task - this is equivalent to using "a single
thread" to execute some work, but is more resource efficient because the task may
suspend while waiting for some work, for example:

```swift
// ✅ Guaranteed order, since caller is a single task
let printer: Printer = ...
await printer.print(1)
await printer.print(2)
await printer.print(3)
```

This code is structurally guaranteed to execute the prints in the expected "1, 2, 3"
order, because the caller is a single task.

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
at all in this `Printer` type, but require that some existing task invokes `await consumeStream()`, like this:

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