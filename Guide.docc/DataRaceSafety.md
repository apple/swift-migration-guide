# Data Race Safety

Learn about the fundamental concepts Swift uses to enable data-race-free
concurrent code.

Traditionally, mutable state had to be manually protected via careful runtime
synchronization.
Using tools such as locks and queues, the prevention of data races was
entirely up to the programmer. This is notoriously difficult
not just to do correctly, but also to keep correct over time.
Even determining the _need_ for synchronization may be challenging.
Worst of all, unsafe code does not guarantee failure at runtime.
This code can often frequently seem to work, possibly requiring highly unusual
conditions to exhibit the incorrect and unpredictable behavior characteristic
of a data race.

More formally, a data race occurs when one thread accesses memory while the
same memory is being mutated by another thread.
The Swift 6 language mode eliminates these problems by preventing data races
at compile time.

> Important: You may have encountered concepts like `async`/`await`
and actors in other languages. Pay extra attention, as similarities to
Swift's implementation may only be superficial.

## Data Isolation

Swift's concurrency system allows the compiler to understand and verify the
safety of all mutable state.
It does this with a mechanism called _data isolation_.
Data isolation guarantees mutually exclusive
access to mutable state. It is a form of synchronization, just like a lock.
But unlike a lock, the protection data isolation provides happens at
compile-time.

A Swift programmer interacts with data isolation in two ways:
statically and dynamically.

The term _static_ is used to describe program elements that are unaffected by
runtime state. These elements, such as a function definition,
are made up of keywords and annotations. Swift's concurrency system is 
an extension of its type system. When you declare functions and types,
you are doing so statically. Isolation can be a part of these static
declarations.

There are cases, however, where the type system alone cannot sufficiently
describe a system's behavior. An example would be an Objective-C function
that has been exposed to Swift. This declaration, made outside of Swift code,
may not provide enough information to the compiler to ensure safe usage. To
accommodate these situations, there are additional features that allow you
to express isolation requirements dynamically.

Data isolation, be it static or dynamic, allows the
compiler to guarantee Swift code you write is free of data races.

### Isolation Domains

Data isolation is the mechanism used to protect shared mutable state.
An independent unit of isolation is referred to as an
_isolation domain_. How much state a particular domain is responsible for
protecting can vary widely. Isolation domains can contain a single variable.
Or, they could protect entire subsystems, like an complete user interface.

The critical feature of an isolation domain is the safety it provides.
Mutable state can only be accessed from one isolation domain at a time.
You can pass mutable state from one isolation domain to another, but you can
never access that state concurrently from different isolation domains
at once without synchronization.
This guarantee is validated by the compiler.

All function and variable declarations have a well-defined static isolation
domain, even if you have not provided one explicitly.

There are three possibilities:

1. Non-isolated
2. Isolated to an actor value
3. Isolated to a global actor

### Non-isolated

Functions and variables do not have to be a part of an explicit isolation
domain.
In fact, a lack of isolation is the default, called _non-isolated_.
This absence of isolation behaves just like a domain all to itself.
Because all the data isolation rules apply,
there is no way for non-isolated code to mutate state protected in another
domain.
As a result of this, non-isolated entities are always safe to
access from any other domain.

```swift
func freeFunction() {
}
```

This top-level function, which has no static isolation, is non-isolated.

```swift
class User {
    var email: String
}
```

As we will see, inheritance can play a role in isolation.
But, this simple class, with no superclass or protocol conformances,
also uses the default of non-isolated.

### Actors

Actors give the programmer a way to define an isolation domain,
along with methods that operate within that domain.
All stored instance properties of an actor are isolated to the enclosing
actor instance.

```swift
actor MyActor {
    var count: 0

    func increment() {
        count += 1
    }
}
```

Here, every `MyActor` instance will define a new domain,
which will be used to protect access to its `count` property.
`MyActor.increment` is isolated to `self`, making `count` accessible within
the function body.

The isolation domain of an actor is not limited to its own methods.
Functions that accept an isolated parameter can also gain access to
actor-isolated state.

```swift
func increment(on myActor: isolated MyActor) {
    myActor.count += 1
}
```

> Note: For an overview of actors, please see the [Actors](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency#Actors)
section of [The Swift Programming Language](https://docs.swift.org/swift-book/documentation/the-swift-programming-language).

### Global Actors

Global actors share all of the properties of regular actors, but also provide
a means of statically assigning declarations to their isolation domain.
This is done with an annotation matching the global actor name.

```swift
@MainActor
class User {
    var email: String
}
```

This class is statically-isolated to `MainActor`. This ensures that all access
to its mutable state is done from that isolation domain.

### Tasks

A `task` is a unit of work that can run concurrently within your program.
Each individual task only executes one function at a time.
But, tasks may run concurrently with respect to each other.

A task always has an isolation domain. They can be isolated to an
actor instance, global actor, or could be non-isolated.
Their isolation, just like all other Swift code, dictates what mutable state
they can access.

Tasks can run both synchronous and asynchronous code. But, regardless of the
structure, functions in the same isolation
domain cannot run concurrently with each other,
but they can run concurrently with functions in other domains.

> Note: For more information see the [Tasks](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency#Tasks-and-Task-Groups)
section of [The Swift Programming Language](https://docs.swift.org/swift-book/documentation/the-swift-programming-language).

## Isolation Boundaries

Isolation domains protect their mutable state. But, useful programs need more
than just protection. They have to make use of that state to produce new data,
consume data, all of which may not originate in the same domain. Moving values
into or out of an isolation domain is known as crossing an isolation boundary.

Values are only ever permitted to cross an isolation boundary where there
is no potential for concurrent access to shared mutable state.

### Sendable Types

In some cases, all values of a particular type are safe to pass across
isolation boundaries because thread safety is a property of the type itself.
This thread-safe property of types is represented by a conformance to the
`Sendable` protocol.
When you see a conformance to `Sendable` in documentation,
it means the given type is thread safe,
and values of the type can be shared across arbitrary isolation domains
without introducing a risk of data races.

Swift encourages using value types because they are naturally safe from
data races.
When you use value types, different parts of your program can't have
shared references to the same value.
When you pass an instance of a value type to a function,
the function has its own independent copy of that value.
Value types in Swift are implicitly `Sendable` within the module when
their stored properties are Sendable, because value semantics guarantees
the absence of shared mutable state.

> Note: While internal value types can be implicitly Sendable,
public value types must explicitly state a conformance to `Sendable`,
because it's part of their public API.

### Actor-Isolated Types

Actors and global-actor-isolated types are also implicitly `Sendable`,
because their mutable state is protected by actor isolation.
It's safe to pass an actor or actor-isolated type across boundaries.
But, execution context must switch back to the actor in order to access its
isolated state.
`nonisolated` properties and functions may still be accessed from outside
the actor, because non-isolated functions cannot access actor-isolated state:

```swift
struct User: Sendable { ... }

@MainActor
class MyModel {
    nonisolated let id: String
    private var users: [User] = []

    nonisolated func printID() {
        print(id)
    }

    func add(user: User) {
        users.append(user)
    }
}
```

In the above code `MyModel` conforms to `Sendable` because all of its
mutable state is isolated to the global actor `MainActor`.
An instance of `MyModel` can be used from outside `MainActor`, but only
the `id` property or the `printID()` method can be used.
A call to `add(user)` from off the `MainActor` is allowed.
But, because that function is isolated, it must be done asynchronously to
provide the runtime the ability to switch to the correct isolation domain.

```swift
let myModel = MyModel(id: "example")
Task.detached {
    myModel.printID()
    await myModel.add(user: User(...))
}
```

### Reference Types

Reference types are only `Sendable` if they do not have any mutable state,
or if the type implements its own synchronization.
`Sendable` is never inferred for class types.
The compiler can only validate the implementation of final classes;
it's safe for a final class to be `Sendable` as long as its stored properties
are either immutable and `Sendable`. This includes types that are implicitly
Sendable because they are isolated to a global actor.

It is possible to implement thread-safety using synchronization primitives
that the compiler cannot reason about, such as through OS-specific constructs
or when working with thread-safe types implemented in C/C++/Objective-C.
Such types may be marked as conforming to `@unchecked Sendable` to tell the
compiler that the type is thread-safe.
The compiler will not perform any checking on an `@unchecked Sendable` type,
so this opt-out must be used with caution.
