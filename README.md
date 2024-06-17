# The Swift Concurrency Migration Guide

This repository contains the source for [The Swift Concurrency Migration Guide][scmg],
which is built using [Swift-DocC][docc].

## Contributing

See [the contributing guide][contributing] for instructions on contributing
to the Swift Migration Guide.

## Building

Run `docc preview Guide.docc` in this repository's root directory.

After running DocC,
open the link that `docc` outputs to display a local preview in your browser.

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

[contributing]: https://github.com/apple/swift-migration-guide/blob/main/CONTRIBUTING.md
[docc]: https://github.com/apple/swift-docc
[conduct]: https://www.swift.org/code-of-conduct
[scmg]: https://www.swift.org/migration/documentation/migrationguide