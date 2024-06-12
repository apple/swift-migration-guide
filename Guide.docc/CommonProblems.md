# Common Compiler Errors

Identify, understand, and address common problems you'll encounter while
working with Swift concurrency.

The data isolation guarantees made by the compiler affect all Swift code.
This means complete concurrency checking can surface latent issues,
even in Swift 5 code that doesn't use any concurrency language features
directly.
And, with the Swift 6 language mode is on, some of these potential issues
can become errors.

After enabling complete checking, many projects can contain a large
number of warnings and errors.
_Don't_ get overwhelmed!
Most of these can be tracked down to a much smaller set of root causes.
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

Here, we have defined a global variable.
The global variable is both non-isolated _and_ mutable from any
isolation domain. Compiling the above code in Swift 6 mode
produces an error message:

```
1 | var islandsInTheSea = 42
  |              |- error: global variable 'islandsInTheSea' is not concurrency-safe because it is non-isolated global shared mutable state
  |              |- note: convert 'islandsInTheSea' to a 'let' constant to make the shared state immutable
  |              |- note: restrict 'islandsInTheSea' to the main actor if it will only be accessed from the main thread
  |              |- note: unsafely mark 'islandsInTheSea' as concurrency-safe if all accesses are protected by an external synchronization mechanism
2 |
```

Two functions with different isolation domains accessing this
variable risks a data race. In the following code, `printIslands()`
could be running on the main actor concurrently with a call to
`addIsland()` from another isolation domain:

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

One way to address the problem is by changing variable's isolation.

```swift
@MainActor
var islandsInTheSea = 42
```

The variable remains mutable, but has been isolated to a global actor.
All accesses can now only happen in one isolation domain, and the synchronous
access within `addIsland` would be invalid at compile time.

If the variable is meant to be constant and is never mutated,
a straight-forward solution is to express this to the compiler.
By changing the `var` to a `let`, the compiler can statically
disallow mutation, guaranteeing safe read-only access.

```swift
let islandsInTheSea = 42
```

If there is synchronization in place that protects this variable in a way that
is invisible to the compiler, you can disable all isolation checking for
`islandsInTheSea` using the `nonisolated(unsafe)` keyword:

```swift
/// This value is only ever accessed while holding `islandLock`.
nonisolated(unsafe) var islandsInTheSea = 42
```

Only use `nonisolated(unsafe)` when you are carefully guarding all access to
the variable with an external synchronization mechanism such as a lock or
dispatch queue.

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
The issue is `Chicken` is a non-Sendable type, making its internal state
unsafe to share across isolation domains.

```swift
func feedPrizedHen() {
    Chicken.prizedHen.currentHunger = .wellFed
}

@MainActor
class ChickenValley {
    var flock: [Chicken]

    func compareHunger() -> Bool {
        flock.contains { $0.currentHunger > Chicken.prizedHen.currentHunger }
    }
}
```

Here, we see two functions that could access the internal state of the
`Chicken.prizedHen` concurrently.
The compiler only permits these kinds of cross-isolation accesses with
`Sendable` types.
One option is to isolate the variable to a single domain using a global actor.
But, it could also make sense to instead add a conformance to `Sendable`
directly.

## Protocol Conformance Isolation Mismatch

A protocol defines requirements that a conforming type must satisfy.
Swift ensures that clients of a protocol can interact with its methods and
properties in a way that respects data isolation.
To do this, both the protocol itself and its requirements must specify
static isolation.
This can result in isolation mismatches between a protocol's declaration and
conforming types.

There are many possible solutions to this class of problem, but they often
involve trade-offs.
Choosing an appropriate approach first requires understanding _why_ there is a
mismatch in the first place.

### Under-Specified Protocol

The most commonly-encountered form of this problem happens when a protocol
has no explicit isolation.
In this case, as with all other declarations, this implies _non-isolated_.
Non-isolated protocol requirements can be called from generic code in any
isolation domain. If the requirement is synchronous, it is invalid for
a conforming type's implementation to access actor-isolated state:

```swift
protocol Styler {
    func applyStyle()
}

@MainActor
class WindowStyler: Styler {
    func applyStyle() {
        // access main-actor-isolated state
    }
}
```

The above code produces the following error in Swift 6 mode:

```
 5 | @MainActor
 6 | class WindowStyler: Styler {
 7 |     func applyStyle() {
   |          |- error: main actor-isolated instance method 'applyStyle()' cannot be used to satisfy nonisolated protocol requirement
   |          `- note: add 'nonisolated' to 'applyStyle()' to make this instance method not isolated to the actor
 8 |         // access main-actor-isolated state
 9 |     }
```

It is possible that the protocol actually _should_ be isolated, but
just has not yet been updated for concurrency.
If conforming types are migrated to add correct isolation first, mismatches
will occur.

```swift
// This really only makes sense to use from MainActor types, but
// has not yet been updated to reflect that.
protocol Styler {
    func applyStyle()
}

// A conforming type, which is now correctly isolated, has exposed 
// a mismatch.
@MainActor
class WindowStyler: Styler {
}
```

#### Adding Isolation

If protocol requirements are always called from the main actor,
adding `@MainActor` is the best solution.

There are two ways to isolate a protocol requirement to the main actor:

```swift
// entire protocol
@MainActor
protocol Styler {
    func applyStyle()
}

// per-requirement
protocol Styler {
    @MainActor
    func applyStyle()
}
```

Marking a protocol with a global actor attribute implies global actor isolation
on all protocol requirements and extension methods. The global actor is also
inferred on conforming types when the conformance is not declared in an
extension.

Per-requirement isolation has a narrower impact on actor isolation inference,
because inference only applies to the implementation of that requirement. It
does not impact the inferred isolation of protocol extensions or other methods
on the conforming type. This approach should be favored if it makes sense to
have conforming types that aren't necessarily also tied to the same global actor.

Either way, changing the isolation of a protocol can affect the isolation of
conforming types and it can impose restrictions on generic code using the
protocol in a generic requirement. You can stage in diagnostics caused by
adding global actor isolation on a protocol using `@preconcurrency`:

```swift
@preconcurrency @MainActor
protocol Styler {
    func applyStyle()
}
```

#### Asynchronous Requirements

For methods that implement synchronous protocol requirements, either the
isolation of method must match the isolation of the requirement exactly,
or the method must be `nonisolated`, meaning it can be called from
any isolation domain without risk of data races. Making a requirement
asynchronous offers a lot more flexibility over the isolation in
conforming types.

```swift
protocol Styler {
    func applyStyle() async
}
```

Because `async` methods guarantee isolation by switching to the corresponding
actor in the implementation, it's possible to satisfy a non-isolated `async`
protocol requirement with an isolated method:

```swift
@MainActor
class WindowStyler: Styler {
    // matches, even though it is synchronous and actor-isolated
    func applyStyle() {
    }
}
```

The above code is safe, because generic code must always call `applyStyle()`
asynchronously, allowing isolated implementations to switch actors before
accessing actor-isolated state.

However, this flexibility comes at a cost.
Changing a method to be asynchronous can have a significant impact at
every call site.
In addition to an async context, both the parameters and return values may
need to cross isolation boundaries.
Together, these could require significant structural changes to address.
This may still be the right solution, but the side-effects should be carefully
considered first, even if only a small number of types are involved.

#### Preconcurrency Conformance

Swift has a number of mechanisms to help you adopt concurrency incrementally
and interoperate with code that has not yet begun using concurrency at all.
These tools can be helpful both for code you do not own, as well as code you
do own, but cannot easily change.

Annotating a protocol conformance with `@preconcurrency` makes it possible to
suppress errors about any isolation mismatches.

```swift
@MainActor
class WindowStyler: @preconcurrency Styler {
    func applyStyle() {
        // implementation body
    }
}
```

This inserts runtime checks to ensure that that static isolation
of the conforming class is always enforced.

> Note: To learn more about incremental adoption and dynamic isolation,
see [Dynamic Isolation][]

[Dynamic Isolation]: incrementaladoption#Dynamic-Isolation

### Isolated Conforming Type

So far, the solutions presented assume that the cause of the isolation
mismatches are ultimately rooted in the protocol definition.
But, it could be that the protocol's static isolation is appropriate,
and the issue instead is only caused by the conforming type.

#### Non-Isolated

Even a completely non-isolated function can still be useful.

```swift
@MainActor
class WindowStyler: Styler {
    nonisolated func applyStyle() {
        // perhaps this implementation doesn't involve
        // other MainActor-isolated state
    }
}
```

The downside to such an implementation is that isolated state and
functions become unavailable.
This is definitely a major constraint, but could still be
appropriate, especially if it is used exclusively as a source of
instance-independent configuration.

#### Conformance by Proxy

It could be possible to use an intermediate type to help address static
isolation differences.
This can be particularly effective if the protocol requires inheritance by its
conforming types.

```swift
class UIStyler {
}

protocol Styler: UIStyler {
    func applyStyle()
}

// actors cannot have class-based inheritance
actor WindowStyler: Styler {
}
```

Introducing a new type to conform indirectly can make this situation work.
However, this solution will require some structural changes to `WindowStyler`
that could spill out code that depends on it as well.

```swift
struct CustomWindowStyle: Styler {
    func applyStyle() {
    }
}
```

Here, a new type has been created that can satisfy the needed inheritance.
Incorporating will be easiest if the conformance is only used internally by
`WindowStyler`.

## Crossing Isolation Boundaries

Any value that needs to move from one isolation domain to another
must either be `Sendable` or must preserve mutually exclusive access.
Using values with types that do not satisfy these requirements in contexts
that require them is a very common problem.
And because libraries and frameworks may be updated to use Swift's
concurrency features, these issues can come up even when your code hasn't
changed.

### Implicitly-Sendable Types

Many value types consist entirely of `Sendable` properties.
The compiler will treat types like this as implicitly `Sendable`, but _only_
when they are non-public.

```swift
public struct ColorComponents {
    public let red: Float
    public let green: Float
    public let blue: Float
}

@MainActor
func applyBackground(_ color: ColorComponents) {
}

func updateStyle(backgroundColor: ColorComponents) async {
    await applyBackground(backgroundColor)
}
```

A `Sendable` conformance is part of a type's public API contract,
and that is up to you to define.
Because `ColorComponents` is marked `public` it will not have an implicit
conformance to `Sendable`.
This will result in the following error:

```
 6 | 
 7 | func updateStyle(backgroundColor: ColorComponents) async {
 8 |     await applyBackground(backgroundColor)
   |           |- error: sending 'backgroundColor' risks causing data races
   |           `- note: sending task-isolated 'backgroundColor' to main actor-isolated global function 'applyBackground' risks causing data races between main actor-isolated and task-isolated uses
 9 | }
10 | 
```

A very straightforward solution is just to make the type's `Sendable`
conformance explicit.

```swift
public struct ColorComponents: Sendable {
    // ...
}
```

Even when trivial, adding a `Sendable` conformance should always be
done with care.
Remember that `Sendable` is a guarantee of thread-safety, and part of a
type's API contract.
Removing the conformance is an API-breaking change.

### Preconcurrency Import

Even if the type in another module is actually `Sendable`, it is not always
possible to modify its definition.
In this case, you can use a `@preconcurrency import` to suppress errors until
the library is updated.

```swift
// ColorComponents defined here
@preconcurrency import UnmigratedModule

func updateStyle(backgroundColor: ColorComponents) async {
    // crossing an isolation domain here
    await applyBackground(backgroundColor)
}
```

With the addition of this `@preconcurrency import`,
`ColorComponents` remains non-`Sendable`.
However, the compiler's behavior will be altered.
When using the Swift 6 language mode, the produced here will be downgraded
to a warning.
The Swift 5 language mode will produce no diagnostics at all.

### Latent Isolation

Sometimes the _apparent_ need for a `Sendable` type can actually be the
symptom of a more fundamental isolation problem.
The only reason a type needs to be `Sendable` is to cross isolation boundaries.
If you can avoid crossing boundaries altogether, the result can
often be both simpler and a better reflection of the true nature of your
system.

```swift
@MainActor
func applyBackground(_ color: ColorComponents) {
}

func updateStyle(backgroundColor: ColorComponents) async {
    await applyBackground(backgroundColor)
}
```

The `updateStyle(backgroundColor:)` function is non-isolated.
This means that its non-`Sendable` parameter is also non-isolated.
But, it is immediately crossing from this non-isolated domain to the
`MainActor` when `applyBackground(_:)` is called.

Since `updateStyle(backgroundColor:)` is working directly with
`MainActor`-isolated functions and non-`Sendable` types,
just applying `MainActor` isolation may be more appropriate.

```swift
@MainActor
func updateStyle(backgroundColor: ColorComponents) async {
    applyBackground(backgroundColor)
}
```

Now, there is no longer an isolation boundary for the non-`Sendable` type to
cross.
And in this case, not only does this resolve the problem, it also
removes the need for an asynchronous call.
Fixing latent isolation issues can also potentially make further API
simplification possible.

Lack of `MainActor` isolation like this is, by far, the most common form of
latent isolation.
It is also very common for developers to hesitate to use this as a solution.
It is completely normal for programs with a user interface to have a large
set of `MainActor`-isolated state.
Concerns around long-running _synchronous_ work can often be addressed with
just a handful of targeted `nonisolated` functions.

### Computed Value

Instead of trying to pass a non-`Sendable` type across a boundary, it may be
possible to use a `Sendable` function that creates the needed values.

```swift
func updateStyle(backgroundColorProvider: @Sendable () -> ColorComponents) async {
    await applyBackground(using: backgroundColorProvider)
}
```

Here, it does not matter than `ColorComponents` is not `Sendable`.
By using `@Sendable` function that can compute the value, the lack of
sendability is side-stepped entirely.

### Sendable Conformance

When encountering problems related to crossing isolation domains, a very
natural reaction is to just try to add a conformance to `Sendable`.
You can make a type `Sendable` in four ways.

#### Global Isolation

Adding global isolation to any type will make it implicitly `Sendable`.

```swift
@MainActor
public struct ColorComponents {
    // ...
}
```

By isolating this type to the `MainActor`, any accesses from other isolation domains
must be done asynchronously.
This makes it possible to safely pass instances around across domains.

#### Actors

Actors have an implicit `Sendable` conformance because their properties are
protected by actor isolation.

```swift
actor Style {
    private var background: ColorComponents
}
```

In addition to gaining a `Sendable` conformance, actors have their own
isolation domain.
This allows them to freely work with other non-`Sendable` types internally.
This can be a major advantage, but does come with trade-offs.

Because an actor's isolated methods all must be asynchronous,
sites that access the type may now require an async context.
This alone is a reason to make such a change with care.
But further, data that is passed into or out of the actor may now itself
need to cross the new isolation boundary.
This can end up resulting in the need for yet more `Sendable` types.

#### Manual Synchronization

If you have a type that is already doing manual synchronization, you can
express this to the compiler by marking your `Sendable` conformance as
`unchecked`.

```swift
class Style: @unchecked Sendable {
    private var background: ColorComponents
    private let queue: DispatchQueue
}
```

You should not feel compelled to remove use of queues, locks, or other
forms of manual synchronization to integrate with Swift's concurrency system.
However, most types are not inherently thread-safe.
As a general rule, if a type isn't already thread-safe, attempting to make
it `Sendable` should not be your first approach.
It is often much easier to try other techniques first, falling back to
manual synchronization only when truly necessary.

#### Sendable Reference Types

It is possible for reference types to be validated as `Sendable` without
the `unchecked` qualifier.
But, this can only be done under very narrow circumstances.

To allow a checked `Sendable` conformance a class:

- Must be `final`
- Cannot inherit from another class other than `NSObject`
- Cannot have any non-isolated mutable properties

```swift
public struct ColorComponents: Sendable {
    // ...
}

final class Style: Sendable {
    private let background: ColorComponents
}
```

Sometimes, this is a sign of a struct in disguise.
But this can still be a useful technique when reference semantics need to be
preserved, or for types that are part of a mixed Swift/Objective-C code base.

#### Using Composition

You do not need to select one single technique for making a reference type
`Sendable.`
One type can use many techniques internally.

```swift
final class Style: Sendable {
    private nonisolated(unsafe) var background: ColorComponents
    private let queue: DispatchQueue

    @MainActor
    private var foreground: ColorComponents
}
```

The `background` property is protected by manual synchronization,
while the `foreground` property uses actor isolation.
Combining these two techniques results in a type that better describes its
internal semantics.
And by doing this, the type can now continue to take advantage of the
compiler's automated isolation checking.

### Non-Isolated Initialization

Actor-isolated types can present a problem when they have to be initialized in
a non-isolated context.
This occurs frequently when the type is used in a default value expression or
as a property initializer.

> Note: These problems could also be a symptom of
[latent isolation](#Latent-Isolation) or an
[under-specified protocol](#Under-Specified-Protocol).

Here the non-isolated `Stylers` type is making a call to a
`MainActor`-isolated initializer.

```swift
@MainActor
class WindowStyler {
    init() {
    }
}

struct Stylers {
    static let window = WindowStyler()
}
```

This code results in the following error:

```
 7 | 
 8 | struct Stylers {
 9 |     static let window = WindowStyler()
   |                `- error: main actor-isolated default value in a nonisolated context
10 | }
11 | 
```

Globally-isolated types sometimes don't actually need to reference any global
actor state in their initializers.
By making the `init` method `nonisolated`, it is free to be called from any
isolation domain.
This remains safe as the compiler still guarantees that any state that *is*
isolated will only be accessible from the `MainActor`.

```swift
@MainActor
class WindowStyler {
    private var viewStyler = ViewStyler()
    private var primaryStyleName: String

    nonisolated init(name: String) {
        self.primaryStyleName = name
        // type is fully-initialized here
    }
}
```


All `Sendable` properties can still be safely accessed in this `init` method.
And while any non-`Sendable` properties cannot,
they can still be initialized by using default expressions.

### Non-Isolated Deinitialization

Even if a type has actor isolation, deinitializers are _always_ non-isolated.

```swift
actor BackgroundStyler {
    // another actor-isolated type
    private let store = StyleStore()

    deinit {
        // this is non-isolated
        store.stopNotifications()
    }
}
```

This code produces the error:

```
error: call to actor-isolated instance method 'stopNotifications()' in a synchronous nonisolated context
 5 |     deinit {
 6 |         // this is non-isolated
 7 |         store.stopNotifications()
   |               `- error: call to actor-isolated instance method 'stopNotifications()' in a synchronous nonisolated context
 8 |     }
 9 | }
```

While this might feel surprising, given that this type is an actor,
this is not a new constraint.
The thread that executes a deinitializer has never been guaranteed and
Swift's data isolation is now just surfacing that fact.

Often, the work being done within the `deinit` does not need to be synchronous.
A solution is to use an unstructured `Task` to first capture and
then operate on the isolated values.
When using this technique,
it is _critical_ to ensure you do not capture `self`, even implicitly.

```swift
actor BackgroundStyler {
    // another actor-isolated type
    private let store = StyleStore()

    deinit {
        // no actor isolation here, so none will be inherited by the task
        Task { [store] in
            await store.stopNotifications()
        }
    }
}
```

> Important: **Never** extend the life-time of `self` from within
`deinit`. Doing so will crash at runtime.
