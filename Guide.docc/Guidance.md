# Guidance

Get recommendations on how to proceed with migrating your project to the
Swift 6 language mode.

Enabling complete concurrency checking in a module can yield many data-race
safety issues reported by the compiler.
Hundreds, possibly even thousands of warnings are not uncommon.
When faced with a such a large number of problems,
especially if you are just beginning to learn about Swift's data isolation
model, this can feel insurmountable.

**Don't panic.**

Frequently, you'll find yourself making substantial progress with just a few
changes.
And as you do, your mental model of how the Swift concurrency system works
will develop just as rapidly.

## Strategy

Of course, there is no one single approach that will work for all projects.
But there is a general strategy that is often very effective.
A recommended approach has three key steps:

- Select a module
- Enable complete checking with Swift 5
- Address warnings

This process will be inherently _iterative_.
Even a single change in one module can have a large impact on the state of the
project as a whole.

## Module Selection

It is often easiest to start with the outer-most root module in a project.
This, by definition, is not a depenency of any other module.
Changes here can only have local effects, making it easier to
keep your changes contained.

## Enable Complete Checking

Don't move directly from Swift 5 with no checking to the Swift 6 language mode.
Instead, first begin by [enabling complete checking][] for a
module that currently still using the Swift 5 mode.
This will surface any potential data safety issues as
warnings, allowing you to keep your build and tests functional as you go.

[enabling complete checking]: <doc:CompleteChecking>

## Address Warnings

There is one guiding principle you should use as you being
tacking warnings: **express what true today**.
Resist the urge to refactor your code to address issues.

You will find it beneficial to minimize the amount of change necessary to
get to a warning-free state with complete concurrency checking.
After that is done, use any unsafe opt-outs you applied as an indication of
follow-on refactoring opportunities to introduce a safer isolation mechanism.

> Note: To learn more about addressing common problems, see <doc:CommonProblems>.

## Iteration

At first, you'll likely be employing techniques to disable or workaround
data isolation problems.
Once you feel like you've reached the stopping point for a higher-level module,
target one of its dependencies that has required a workaround.
