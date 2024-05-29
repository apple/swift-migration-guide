# The Swift Concurrency Migration Guide

This repository contains the source for *The Swift Concurrency Migration Guide*,
which is published on [docs.swift.org][published]
and built using [Swift-DocC][docc].

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

[asg]: https://help.apple.com/applestyleguide/
[bugs]: https://github.com/apple/swift-migration-guide/issues
[contributing]: https://github.com/apple/swift-book/CONTRIBUTING.md
[docc]: https://github.com/apple/swift-docc
[conduct]: https://www.swift.org/code-of-conduct
[published]: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/
[tspl-style]: https://github.com/apple/swift-book/Style.md