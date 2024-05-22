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

> Important: You may have encountered constructs like `async`/`await`
and actors in other languages. Pay extra attention, as similarities to
these concepts in Swift may only be superficial.

## Data Isolation

Swift's concurrency system allows the compiler to understand and verify the
safety of all mutable state.
It does this with a mechanism called _data isolation_.
Data isolation guarantees mutually exclusive
access to mutable state. It is a form of synchronization,
conceptually similar to a lock.
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
describe a system's behavior. An example could be an Objective-C type
that has been exposed to Swift. This declaration, made outside of Swift code,
may not provide enough information to the compiler to ensure safe usage. To
accommodate these situations, there are additional features that allow you
to express isolation requirements dynamically.

Data isolation, be it static or dynamic, allows the
compiler to guarantee Swift code you write is free of data races.

### Isolation Domains

Data isolation is the _mechanism_ used to protect shared mutable state.
But, it is often useful to talk about an independent unit of isolation.
This is known as an _isolation domain_.
How much state a particular domain is responsible for
protecting can vary widely. Isolation domains can contain a single variable.
Or, they could protect entire subsystems, like an complete user interface.

The critical feature of an isolation domain is the safety it provides.
Mutable state can only be accessed from one isolation domain at a time.
You can pass mutable state from one isolation domain to another, but you can
never access that state concurrently from a different domain.
This guarantee is validated by the compiler.

Even if you have not explicitly defined it yourself,
_all_ function and variable declarations have a well-defined static
isolation domain.
These domains will always fall into one of three categories:

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

<!--
  REFERENCE
  "Sea", in the context of concurrency, is a reference to the WWDC 2022 session
  "Eliminate data races using Swift Concurrency".

  Types like Island, Chicken, and Pineapple are also featured in that video.

  https://developer.apple.com/wwdc22/110351
-->

```swift
func sailTheSea() {
}
```

This top-level function which has no static isolation, making it non-isolated.
It can safely call other non-isolated functions and access non-isolated
variables.
But, it cannot access anything from another isolation domain.

```swift
class Chicken {
    let name: String
    var currentHunger: HungerLevel
}
```

This is an example of a non-isolated type.
Inheritance can play a role in static isolation.
But, this simple class, with no superclass or protocol conformances,
also uses the default isolation.

Data isolation guarantees that non-isolated entities cannot access the mutable
state from other domains.
As a result of this, non-isolated functions and variables are always safe to
access from any other domain.

### Actors

Actors give the programmer a way to define an isolation domain,
along with methods that operate within that domain.
All stored instance properties of an actor are isolated to the enclosing
actor instance.

```swift
actor Island {
    var flock: [Chicken]
    var food: [Pineapple]

    func addToFlock() {
        flock.append(Chicken())
    }
}
```

Here, every `Island` instance will define a new domain,
which will be used to protect access to its properties.
The method `Island.addToFlock` is said to be isolated to `self`.
The body of a method has access to all data that shares its isolation domain,
making the `flock` property synchronously accessible.

Actor isolation can be selectively disabled.
This can be useful any time you want to keep code organized within an
isolated type, but opt-out of the isolation requirements that go along with it.
Non-isolated methods cannot synchronously access any protected state.

```swift
actor Island {
    var flock: [Chicken]
    var food: [Pineapple]

    nonisolated func canGrow() -> PlantSpecies {
        // neither flock nor food are accessible here
    }
}
```

The isolation domain of an actor is not limited to its own methods.
Functions that accept an isolated parameter can also gain access to
actor-isolated state without the need for any other form of synchronization.

```swift
func addToFlock(of island: isolated Island) {
    island.flock.append(Chicken())
}
```

> Note: For an overview of actors, please see the [Actors](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency#Actors)
section of [The Swift Programming Language](https://docs.swift.org/swift-book/documentation/the-swift-programming-language).

### Global Actors

Global actors share all of the properties of regular actors, but also provide
a means of statically assigning declarations to their isolation domain.
This is done with an annotation matching the actor name.
Global actors are particularly useful when groups of types all need to interoperate as a single pool of shared mutable state.

```swift
@MainActor
class ChickenValley {
    var flock: [Chicken]
    var food: [Pineapple]
}
```

This class is statically-isolated to `MainActor`. This ensures that all access
to its mutable state is done from that isolation domain.

You can opt-out of this type of actor isolation as well,
using the `nonisolated` keyword.
And just as with actor types,
doing so will disallow access to any protected state.

```swift
@MainActor
class ChickenValley {
    var flock: [Chicken]
    var food: [Pineapple]

    nonisolated func canGrow() -> PlantSpecies {
        // neither flock, food, nor any other MainActor-isolated
        // state is accessible here
    }
}
```

### Tasks

A `task` is a unit of work that can run concurrently within your program.
You cannot run concurrent code in Swift outside of a task,
but that doesn't mean you must always manually start one.
Typically, asynchronous functions do not need to be aware of the
task running them.
In fact, tasks can often begin at a much higher level,
within an application framework, or even at the root of a program.

Tasks may run concurrently with one another,
but each individual task only executes one function at a time.
They run code in order, from beginning to end.

```swift
Task {
    flock.map(Chicken.produce)
}
```

A task always has an isolation domain. They can be isolated to an
actor instance, a global actor, or could be non-isolated.
This isolation can be established manually, but can also be inherited
automatically based on context.
Task isolation, just like all other Swift code, determines what mutable state
they can access.

Tasks can run both synchronous and asynchronous code. But, regardless of the
structure and how many tasks are involved, functions in the same isolation
domain cannot run concurrently with each other.
There will only ever be one task running synchronous code for any given isolation domain.

> Note: For more information see the [Tasks](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency#Tasks-and-Task-Groups)
section of [The Swift Programming Language](https://docs.swift.org/swift-book/documentation/the-swift-programming-language).

## Isolation Boundaries

Isolation domains protect their mutable state. But, useful programs need more
than just protection. They have to communicate and coordinate,
often by passing data back and forth.
Moving values into or out of an isolation domain is known as crossing an
isolation boundary.

Values are only ever permitted to cross an isolation boundary where there
is no potential for concurrent access to shared mutable state.

### Sendable Types

In some cases, all values of a particular type are safe to pass across
isolation boundaries because thread-safety is a property of the type itself.
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
Because value semantics guarantees the absence of shared mutable state, value
types in Swift are implicitly `Sendable` when all their stored properties
are also Sendable.
However, this implicit conformance is not visible outside of their
defining module.
Making a class `Sendable` is part of its public API contract,
and must always be done explicitly.

```swift
enum Ripeness {
    case hard
    case perfect
    case mushy(daysPast: Int)
}

struct Pineapple {
    var weight: Double
    var ripeness: Ripeness
}
```

Here, both the `Ripeness` and `Pineapple` types are implicitly `Sendable`,
since they are composed entirely of `Sendable` value types.

> Note: For more information see the [Sendable Types](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency#Sendable-Types)
section of [The Swift Programming Language](https://docs.swift.org/swift-book/documentation/the-swift-programming-language).

### Actor-Isolated Types

Actors are not value types. But, because they protect all of their state
in their own isolation domain,
they are inherently safe to pass across boundaries.
This makes all actor types implicitly `Sendable`.

```swift
actor Island {
    var flock: [Chicken]
    var food: [Pineapple]
}
```

Global-actor-isolated types are also implicitly `Sendable` for similar reasons.
They do not have a private, dedicated isolation domain, but their state is still
protected by an actor.

```swift
@MainActor
class ChickenValley {
    var flock: [Chicken]
    var food: [Pineapple]
}
```

Being `Sendable`, actor and global-actor-isolated type are always safe
to pass across isolation boundaries.

### Reference Types

Unlike value types, reference types cannot be implicitly `Sendable`.
And while they can be made `Sendable`,
doing so comes with a number of constraints.
To make a class `Sendable`, it must contain no mutable state.
And any immutable properties must also be `Sendable`.
Further, the compiler can only validate the implementation of final classes.

```swift
final class Chicken: Sendable {
    let name: String
}
```

It is possible to satisfy the thread-safety requirements of `Sendable`
using synchronization primitives that the compiler cannot reason about,
such as through OS-specific constructs or
when working with thread-safe types implemented in C/C++/Objective-C.
Such types may be marked as conforming to `@unchecked Sendable` to promise the
compiler that the type is thread-safe.
The compiler will not perform any checking on an `@unchecked Sendable` type,
so this opt-out must be used with caution.

### Suspension Points

A task can switch between isolation domains when a function in one
isolation domain calls a function in a different domain.
When a call crosses an isolation boundary,
that call must be made asynchronously,
because the destination isolation domain might be busy running other tasks.
In that case, the task will be suspended until the destination isolation
domain is free to run the function.
Critically, a suspension point does not block.
The current isolation domain (and the thread it is currently running on)
are freed up to perform other work.
The Swift concurrency runtime expects code to never block on future work,
allowing the system to always make forward progress,
which eliminates a common source of deadlocks in concurrent code.

Potential suspension points are marked in source code with the `await` keyword.
The await keyword indicates that the call might suspend at runtime;
`await` does not force a suspension, and the function being called might
only suspend under certain dynamic conditions.
It's possible that a call marked with await doesn't actually suspend.
In any case, explicitly marking potential suspension points is important
in concurrent code because suspensions indicate the end of a critical section.
Because the current isolation domain is freed up to perform other work,
actor-isolated state may change across a suspension point.
As such, your critical sections should always be written in synchronous code.

> Note: For more information, see the [Defining and Calling Asynchronous Functions](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/#Defining-and-Calling-Asynchronous-Functions)
section of [The Swift Programming Language](https://docs.swift.org/swift-book/documentation/the-swift-programming-language).
