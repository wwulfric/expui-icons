# Icons

SVG icons from IntelliJ's New UI, copied unmodified by
[`../scripts/update-icons.sh`](../scripts/update-icons.sh) from the entries in
[`../scripts/manifest.txt`](../scripts/manifest.txt):

- the whole `expui` set of
  [intellij-community](https://github.com/JetBrains/intellij-community)'s
  platform, plus the Python and Kotlin file-type icons;
- file-type icons of other JetBrains plugins (Go, Rust, Ruby, JavaScript,
  CLion, …) from [IntelliJ Platform Icons](https://intellij-icons.jetbrains.design),
  the site where JetBrains publishes these icons for plugin developers.

File-type icons have plain names (`go.svg`); the other platform icons keep
IntelliJ's directories (`nodes/`, `general/`, …).  `NAME_dark.svg` is the
variant for dark backgrounds, where upstream has one.

## License

The icons are © JetBrains s.r.o. and contributors, licensed under the Apache
License 2.0: see `LICENSE.txt` and `NOTICE.txt`.  (intellij-community's
top-level `LICENSE.txt` covers JetBrains' binary builds, not these sources.)

The site states that its icons are Apache 2.0.  Some of its files, such as
the Go and Rust icons, lack the license header the others carry; they are
included on the understanding that the statement covers them too.  If you
hold the rights to any of them and disagree, please open an issue.

Logos of languages and tools are trademarks of their owners.
