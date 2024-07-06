# Source Compatibility

See an overview of potential source compatibility issues.

Swift 6 includes a number of evolution proposals that could potentially affect
source compatibility.
These are all opt-in for the Swift 5 language mode.

> Note: For the previous release’s Migration Guide, see [Migrating to Swift 5][swift5].

[swift5]: https://www.swift.org/migration-guide-swift5/

## Handling Future Enum Cases

[SE-0192][]: `NonfrozenEnumExhaustivity`

Lack of a required `@unknown default` has changed from a warning to an error.

[SE-0192]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0192-non-exhaustive-enums.md

## Concise magic file names

[SE-0274][]: `ConciseMagicFile`

The special expression `#file` has changed to a human-readable string
containing the filename and module name.

[SE-0274]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0274-magic-file.md

## Forward-scan matching for trailing closures

[SE-0286][]: `ForwardTrailingClosures`

Could affect code involving multiple, defaulted closure parameters.

[SE-0286]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0286-forward-scan-trailing-closures.md

## Incremental migration to concurrency checking

[SE-0337][]: `StrictConcurrency`

Will introduce errors for any code that risks data races.

[SE-0337]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0337-support-incremental-migration-to-concurrency-checking.md

> Note: This feature implicitly also enables [`IsolatedDefaultValues`](#Isolated-default-value-expressions),
[`GlobalConcurrency`](#Strict-concurrency-for-global-variables),
and [`RegionBasedIsolation`](#Region-based-Isolation).

## Implicitly Opened Existentials

[SE-0352][]: `ImplicitOpenExistentials`

Could affect overload resolution for functions that involve both
existentials and generic types.

[SE-0352]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0352-implicit-open-existentials.md

## Regex Literals

[SE-0354][]: `BareSlashRegexLiterals`

Could impact the parsing of code that was previously using a bare slash.

[SE-0354]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0354-regex-literals.md

## Deprecate @UIApplicationMain and @NSApplicationMain

[SE-0383][]: `DeprecateApplicationMain`

Will introduce an error for any code that has not migrated to using `@main`.

[SE-0383]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0383-deprecate-uiapplicationmain-and-nsapplicationmain.md

## Importing Forward Declared Objective-C Interfaces and Protocols

[SE-0384][]: `ImportObjcForwardDeclarations`

Will expose previously-invisible types that could conflict with existing
sources.

[SE-0384]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0384-importing-forward-declared-objc-interfaces-and-protocols.md

## Remove Actor Isolation Inference caused by Property Wrappers

[SE-0401][]: `DisableOutwardActorInference`

Could change the inferred isolation of a type and its members.

[SE-0401]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0401-remove-property-wrapper-isolation.md

## Isolated default value expressions

[SE-0411][]: `IsolatedDefaultValues`

Will introduce errors for code that risks data races.

[SE-0411]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0411-isolated-default-values.md

##  Strict concurrency for global variables

[SE-0412][]: `GlobalConcurrency`

Will introduce errors for code that risks data races.

[SE-0412]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0412-strict-concurrency-for-global-variables.md

## Region based Isolation

[SE-0414][]: `RegionBasedIsolation`

Increases the constraints of the `Actor.assumeIsolated` function.

[SE-0414]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0414-region-based-isolation.md

## Inferring `Sendable` for methods and key path literals

[SE-0418][]: `InferSendableFromCaptures`

Could affect overload resolution for functions that differ only by sendability.

[SE-0418]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0418-inferring-sendable-for-methods.md

## Dynamic actor isolation enforcement from non-strict-concurrency contexts

[SE-0423][]: `DynamicActorIsolation`

Introduces new assertions that could affect existing code if the runtime
isolation does not match expectations.

[SE-0423]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0423-dynamic-actor-isolation.md

## Usability of global-actor-isolated types

[SE-0434][]: `GlobalActorIsolatedTypesUsability`

Could affect type inference and overload resolution for functions that are
globally-isolated but not `@Sendable`. 

[SE-0434]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0434-global-actor-isolated-types-usability.md
