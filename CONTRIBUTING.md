# Contributing to the Swift Migration Guide

## Welcome the Swift community!

Contributions to the Swift project are welcomed and encouraged!
Please see the [Contributing to Swift guide](https://www.swift.org/contributing/)
and check out the structure of the community.

To be a truly great community, Swift needs to welcome developers from all walks
of life, with different backgrounds, and with a wide range of experience. A
diverse and friendly community will have more great ideas, more unique
perspectives, and produce more great code. We will work diligently to make the
Swift community welcoming to everyone.

To give clarity of what is expected of our members, Swift has adopted the code
of conduct defined by the Contributor Covenant. This document is used across
many open source communities, and we think it articulates our values well. 
For more, see the [Code of Conduct](https://www.swift.org/code-of-conduct/).

## Contributing to swift-migration-guide
 
### How you can help

We would love your contributions in the form of:
- Filing issues to cover specific code patterns or additional sections of the
  guide
- Opening pull requests to improve existing content or add new content
- Reviewing others' pull requests for clarity and correctness of writing
  and code examples

### Submitting Issues and Pull Requests

#### Issues

File bugs about the content using the [issues page][bugs] on Github.

#### Opening pull requests

To create a pull request, fork this repository, push your change to
a branch, and open a pull request against the `main` branch.

#### Build and test

Run `docc preview Guide.docc` in this repository's root directory.

After running DocC, open the link that `docc` outputs to display a local
preview in your browser.

> Note:
>
> If you installed DocC by downloading a toolchain from Swift.org,
> `docc` is located in `usr/bin/`,
> relative to the installation path of the toolchain.
> Make sure your shell's `PATH` environment variable
> includes that directory.
>
> If you installed DocC by downloading Xcode,
> use `xcrun docc` instead.

#### Running CI

Pull requests must pass CI testing via `@swift-ci please test` before the change is merged.

### Getting your PR reviewed 

Reviewers will be tagged automatically when you open a pull request. You may
be asked to make changes during code review. When you are ready, use the
request re-review feature of github or mention the reviewers by name in a comment.

[bugs]: https://github.com/apple/swift-migration-guide/issues