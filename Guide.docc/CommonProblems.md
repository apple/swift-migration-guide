# Common Problems

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
just easy to fix, but can also very instructive in helping to understand how
Swift's data isolation model.

## Unsafe Global and Static Variables

Global state, including static variables, are accessible from anywhere in a
program.
This visibility makes them particularly susceptible to unsafe usage.
Frequently, global state is defined with language constructs that permit
data-race-prone accesses, and simply rely on programmers never actually
using them in an unsafe way.

### Sendable Types

```swift
var islandsInTheSea = 42
```

Here, we have defined global state that allows mutation from any program
context.
The declaration is both non-isolated _and_ mutable from any
isolation domain.
These are in conflict -- there is no way for the compiler to statically
enforce safety.
Even though this is a `Sendable` value type, it is the mutable nature of the
variable that presents the problem.

```swift
let islandsInTheSea = 42
```

If this value truly represents a constant, a very straight-forward solution is
to simply express this to the compiler.
By changing the `var` to a `let`, the compiler can statically
disallow mutation, guaranteeing safe read-only access.

But, perhaps this value actually does need to be changed.
In this case, instead of changing the mutability, we can ensure safety by
changing the isolation.

```swift
@MainActor
var islandsInTheSea = 42
```

The variable remains mutable, but has been isolated to a global actor.
All accesses can now only happen in one isolation domain.

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

To address this lack of sendability, see the section on making types Sendable
(forthcoming).

> Examples of diagnostics produced by the Swift 5.10 compiler for these issues include:  
>  
> `Let '_' is not concurrency-safe because it is not either conforming to 'Sendable' or isolated to a global actor; this is an error in Swift 6`  
>  
> `Reference to static property '_' is not concurrency-safe because it involves shared mutable state; this is an error in Swift 6`  
>  
> `Static property '_' is not concurrency-safe because it is non-isolated global shared mutable state; this is an error in Swift 6`  
>  
> `Static property '_' is not concurrency-safe because it is not either conforming to 'Sendable' or isolated to a global actor; this is an error in Swift 6`
