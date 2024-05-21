# Migrating to the Swift 6 Language Mode

@Metadata {
  @TechnologyRoot
}

@Options(scope: global) {
  @AutomaticSeeAlso(disabled)
  @AutomaticTitleHeading(disabled)
  @AutomaticArticleSubheading(disabled)
}

## Overview

Swift's concurrency system makes asynchronous and parallel code
easier to write and understand. Concurrency features have been introduced
into the language gradually, and prior to Swift 6, many were optional.
With the introduction of the Swift 6 language mode, the compiler can now also
guarantee that concurrent programs are data-race-free.
But, this also means in this mode these features and checks
are no longer optional.

It is possible you have been incrementally adopting all concurrency features
as they were introduced.
Or, you may have been waiting for Swift 6 to being
adopting them.
Regardless of where your project is in this process, this guide exists to
provide concepts and practical help to ease this migration.

Here you will find articles and code examples that will:

- Explain the concepts used by Swift's data-race safety model.
- Help you enable strict concurrency checking with Swift 5 projects.
- Provide techniques for incremental adoption.
- Discuss common problems with strategies to resolve them.

> Important: The Swift 6 language mode is opt-in.
Existing projects will not switch to this mode without configuation changes.

## Topics

- <doc:DataRaceSafety>
- <doc:StrictChecking>
- <doc:IncrementalAdoption>
- <doc:CommonProblems>