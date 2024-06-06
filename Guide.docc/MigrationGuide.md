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
modules that have been migrated to Swift 6.

It is possible you have been incrementally adopting concurrency features
as they were introduced.
Or, you may have been waiting for Swift 6 to begin using them.
Regardless of where your project is in this process, this guide provides
concepts and practical help to ease the migration.

Here you will find articles and code examples that will:

- Explain the concepts used by Swift's data-race safety model.
- Demonstrate how to enable the Swift 6 language mode.
- Show how to enable complete concurrency checking for Swift 5 projects.
- Provide techniques for incremental adoption.
- Present strategies to resolve common problems.

> Important: The Swift 6 language mode is opt-in.
Existing projects will not switch to this mode without configuration changes.

## Topics

- <doc:DataRaceSafety>
- <doc:Swift6Mode>
- <doc:CompleteChecking>
- <doc:IncrementalAdoption>
- <doc:CommonProblems>
