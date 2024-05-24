# Common Compiler Errors

Identify, understand, and address problems that frequently come up while working
with Swift concurrency.

The data isolation guarantees made by the compiler affect all Swift code.
This means strict concurrency checking can surface latent issues,
even in Swift 5 code that doesn't use any concurrency language features
directly.
And, with the Swift 6 language mode is on, some of these potential issues
can become errors.

After enabling strict checking, many projects can contain a large
number of warnings and errors.
_Don't_ get overwhelmed!
Most of these can be tracked to a much smaller set of root causes.
And these causes, frequently, are a result of common patterns which aren't 
just easy to fix, but can also very instructive in helping to understand
Swift's data isolation model.

## Unsafe Global and Static Variables

Global state, including static variables, are accessible from anywhere in a
program.
This visibility makes them particularly susceptible to concurrent access.
Before data-race safety, global variable patterns relied on programmers
carefully accessing global state in ways that avoided data-races
without any help from the compiler.

### Sendable Types

```swift
var islandsInTheSea = 42
```

Here, we have defined global state that allows mutation from any program
context.
The declaration is both non-isolated _and_ mutable from any
isolation domain.
These two poperties are are in conflict.
Even though this is a `Sendable` value type, there is no way for the
compiler to statically enforce safety.

```swift
@MainActor
func printIslands() {
    print("Islands in the sea of concurrency: ", islandsInTheSea)
}

func addIsland() {
    let island = Island()

    islandsInTheSea += 1

    addToMap(island)
}
```

If we had two functions with different isolation domains that access this
variable, there is a possibility for a race.
One way to address the problem is by changing variable's isolation.

```swift
@MainActor
var islandsInTheSea = 42
```

The variable remains mutable, but has been isolated to a global actor.
All accesses can now only happen in one isolation domain, and the synchronous
access within `addIsland` would be disallowed.

It's also possible the intention was for this value to represent a constant.
In that case, a very straight-forward solution is to simply express this
to the compiler.
By changing the `var` to a `let`, the compiler can statically
disallow mutation, guaranteeing safe read-only access.

```swift
let islandsInTheSea = 42
```

There is also the possibility that there is synchronization in place that
protects this variable in a way that is invisible to the compiler.
You can express this state to the compiler to disable all isolation
checking for `islandsInTheSea`.
Like all manual synchronization, this something you should always do
carefully.

```swift
/// This value is only ever accessed while holding `islandLock`.
nonisolated(unsafe) var islandsInTheSea = 42
```

There are many other mechansims for expressing manual synchronzation,
described in [Opting-Out of Isolation Checking][] (forthcoming).

[Opting-Out of Isolation Checking]: #

### Non-Sendable Types

In the above examples, the variable is an `Int`,
a value type that is inherently `Sendable`.
Global _reference_ types present an additional challenge, because they
are typically not `Sendable`.

```swift
class Chicken {
    let name: String
    var currentHunger: HungerLevel

    static let prizedHen = Chicken()
}
```

The problem with this `static let` declaration is not related to the
mutability of the variable.
The issue is `Chicken` is non-Sendable, making it unsafe to share access
across isolation domains.

To address this lack of sendability, see the section on
[Making Types Sendable][] (forthcoming).

[Making Types Sendable]: #

> Examples of diagnostics produced by the Swift 5.10 compiler for these issues include:  
>  
> `Let '_' is not concurrency-safe because it is not either conforming to 'Sendable' or isolated to a global actor; this is an error in Swift 6`  
>  
> `Reference to static property '_' is not concurrency-safe because it involves shared mutable state; this is an error in Swift 6`  
>  
> `Static property '_' is not concurrency-safe because it is non-isolated global shared mutable state; this is an error in Swift 6`  
>  
> `Static property '_' is not concurrency-safe because it is not either conforming to 'Sendable' or isolated to a global actor; this is an error in Swift 6`
