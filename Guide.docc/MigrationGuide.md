# Migrating to Swift 6

@Metadata {
  @TechnologyRoot
}

@Options(scope: global) {
  @AutomaticSeeAlso(disabled)
  @AutomaticTitleHeading(disabled)
  @AutomaticArticleSubheading(disabled)
}

## Overview

Swift's concurrency system, introduced in [Swift 5.5](https://www.swift.org/blog/swift-5.5-released/),
makes asynchronous and parallel code easier to write and understand.
With the Swift 6 language mode, the compiler can now 
guarantee that concurrent programs are free of data races.
When enabled, compiler safety checks that were
previously optional become required.

Adopting the Swift 6 language mode is entirely under your control
on a per-target basis.
Targets that build with previous modes, as well as code in other
languages exposed to Swift, can all interoperate with
modules that have been migrated to the Swift 6 language mode.

It is possible you have been incrementally adopting concurrency features
as they were introduced.
Or, you may have been waiting for the Swift 6 release to begin using them.
Regardless of where your project is in this process, this guide provides
concepts and practical help to ease the migration.

Here you will find articles and code examples that will:

- Explain the concepts used by Swift's data-race safety model.
- Outline a possible way to get started with migration.
- Show how to enable complete concurrency checking for Swift 5 projects.
- Demonstrate how to enable the Swift 6 language mode.
- Present strategies to resolve common problems.
- Provide techniques for incremental adoption.

> Important: The Swift 6 language mode is _opt-in_.
Existing projects will not switch to this mode without configuration changes.
>
> There is an important distinction between the _compiler version_
and _language mode_.
The Swift 6 compiler supports four distinct language modes: "6", "5", "4.2",
and "4".

> Note: This guide is under active development. You can view the source, see
full code examples, and learn about how to contribute in the [repository][].

[repository]: https://github.com/apple/swift-migration-guide

## Topics

- <doc:DataRaceSafety>
- <doc:MigrationStrategy>
- <doc:CompleteChecking>
- <doc:Swift6Mode>
- <doc:CommonProblems>
- <doc:IncrementalAdoption>

### Swift Concurrency in Depth

- <doc:RuntimeBehavior>
