# Library Evolution

Annotate library APIs for concurrency while preserving source and ABI
compatibility.

Concurrency annotations such as `@MainActor` and `@Sendable` can impact source
and ABI compatibility. Library authors should be aware of these implications when
annotating existing APIs.

## Preconcurrency annotations

The `@preconcurrency` attribute can be used directly on library APIs to
stage in new concurrency requirements that are checked at compile time
without breaking source or ABI compatibility for clients:

```swift
@preconcurrency @MainActor
struct S { ... }

@preconcurrency
public func performConcurrently(
  completion: @escaping @Sendable () -> Void
) { ... }
```

Clients do not need to use a `@preconcurrency import` for the new errors
to be downgraded. If the clients build with minimal concurrency checking,
errors from `@preconcurrency` APIs will be suppressed. If the clients build
with complete concurrency checking or the Swift 6 language mode, the errors
will be downgraded to warnings.

For ABI compatibility, `@preconcurrency` will mangle symbol names without any
concurrency annotations. If an API was introduced with some concurrency
annotations, and is later updated to include additional concurrency
annotations, then applying `@preconcurrency` is not sufficient for preserving
mangling. `@_silgen_name` can be used in cases where you need more precise
control over mangling concurrency annotations.

Note that all APIs imported from C, C++, and Objective-C are automatically
considered `@preconcurrency`. Concurrency attributes can always be applied
to these APIs using `__attribute__((__swift_attr__("<attribute name>")))`
without breaking source or ABI compatibility.

## Sendable

### Conformances on concrete types

Adding a `Sendable` conformance to a concrete type, including conditional
conformances, is typically a source compatible change in practice.

**Source and ABI compatible:**

```diff
-public struct S
+public struct S: Sendable
```

Like any other conformance, adding a conformance to `Sendable` can change
overload resolution if the concrete type satisfies more specialized
requirements. However, it's unlikely that an API which overloads on a
`Sendable` conformance would change type inference in a way that breaks
source compatibility or program behavior.

Adding a `Sendable` conformance to a concrete type, and not one of its type
parameters, is always an ABI compatible change.

### Generic requirements

Adding a `Sendable` conformance requirement to a generic type or function is
a source incompatible change, because it places a restriction on generic
arguments passed by the client.

**Source and ABI incompatible:**

```diff
-public func generic<T>
+public func generic<T> where T: Sendable
```

**To resolve:** Apply `@preconcurrency` to the type or function declaration to
downgrade requirement failures to warnings and preserve ABI:

```swift
@preconcurrency
public func generic<T> where T: Sendable { ... }
```

### Function types

Like generic requirements, adding `@Sendable` to a function type is a 
source and ABI incompatible change:

**Source and ABI incompatible:**

```diff
-public func performConcurrently(completion: @escaping () -> Void)
+public func performConcurrently(completion: @escaping @Sendable () -> Void)
```

**To resolve:** Apply `@preconcurrency` to the enclosing function declaration
to downgrade requirement failures to warnings and preserve ABI:

```swift
@preconcurrency
public func performConcurrently(completion: @escaping @Sendable () -> Void)
```

## Main actor annotations

### Protocols and types

Adding `@MainActor` annotations to protocols or type declarations is a source
and ABI incompatible change.

**Source and ABI incompatible:**

```diff
-public protocol P
+@MainActor public protocol P

-public class C
+@MainActor public class C
```

Adding `@MainActor` to protocols and type declarations has a wider impact than
other concurrency annotations because the `@MainActor` annotation can be
inferred throughout client code, including protocol conformances, subclasses,
and extension methods.

Applying `@preconcurrency` to the protocol or type declaration will downgrade
actor isolation errors based on the concurrency checking level. However,
`@preconcurrency` is not sufficient for preserving ABI compatibility for
clients in cases where the `@preconcurrency @MainActor` annotation can be
inferred on other declarations in client code. For example, consider the
following API in a client library:

```swift
extension P {
  public func onChange(action: @escaping @Sendable () -> Void)
}
```

If `P` is retroactively annotated with `@preconcurrency @MainActor`, these
annotations will be inferred on the extension method. If an extension method is
also part of a library with ABI compatibility constraints, then
`@preconcurrency` will strip all concurrency related annotations from mangling.
This can be worked around in the client library either by applying the
appropriate isolation explicitly, such as:

```swift
extension P {
  nonisolated public func onChange(action: @escaping @Sendable () -> Void)
}
```

Language affordances for precise control over the ABI of a declaration are
[under development](https://forums.swift.org/t/pitch-controlling-the-abi-of-a-declaration/75123).

### Function declarations and types

Adding `@MainActor` to a function declaration or a function type is a
source and ABI incompatible change.

**Source and ABI incompatible:**

```diff
-public func runOnMain()
+@MainActor public func runOnMain()

-public func performConcurrently(completion: @escaping () -> Void)
+public func performConcurrently(completion: @escaping @MainActor () -> Void)
```

**To resolve:** Apply `@preconcurrency` to the enclosing function declaration
to downgrade requirement failures to warnings and preserve ABI:

```swift
@preconcurrency @MainActor
public func runOnMain() { ... }

@preconcurrency
public func performConcurrently(completion: @escaping @MainActor () -> Void) { ... }
```

## `sending` parameters and results

Adding `sending` to a result lifts restrictions in client code, and is
always a source and ABI compatible change:

**Source and ABI compatible:**

```diff
-public func getValue() -> NotSendable
+public func getValue() -> sending NotSendable
```

However, adding `sending` to a parameter is more restrictive at the caller.

**Source and ABI incompatible:**

```diff
-public func takeValue(_: NotSendable)
+public func takeValue(_: sending NotSendable)
```

There is currently no way to stage in a new `sending` annotation on a parameter
without breaking source compatibility.

### Replacing `@Sendable` with `sending`

Replacing an existing `@Sendable` annotation with `sending` on a closure
parameter is a source compatible, ABI incompatible change.

**Source compatible, ABI incompatible:**

```diff
-public func takeValue(_: @Sendable @escaping () -> Void)
+public func takeValue(_: sending @escaping () -> Void)
```

**To resolve:** Adding `sending` to a parameter changes name mangling, so any
adoption must preserve the mangling using `@_silgen_name`. Adopting `sending`
in parameter position must preserve the ownership convention of parameters. No
additional annotation is necessary if the parameter already has an explicit
ownership modifier. For all functions except initializers, use
`__shared sending` to preserve the ownership convention:

```swift
public func takeValue(_: __shared sending NotSendable)
```

For initializers, `sending` preserves the default ownership convention, so it's not
necessary to specify an ownership modifier when adopting `sending` on initializer
parameters:

```swift
public class C {
  public init(ns: sending NotSendable)
}
```
