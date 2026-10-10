# Icons

SVG icons from IntelliJ's New UI, copied unmodified from
[JetBrains/intellij-community](https://github.com/JetBrains/intellij-community)
at the commit in [`../scripts/COMMIT`](../scripts/COMMIT), by
[`../scripts/update-icons.sh`](../scripts/update-icons.sh) from the paths in
[`../scripts/manifest.txt`](../scripts/manifest.txt):

- every icon in `platform/icons/src/expui/`: `fileTypes/NAME.svg` becomes
  `NAME.svg` here, and every other directory is kept (`nodes/`, `general/`,
  `actions/`, …).  Size variants (`NAME@20x20.svg`) are left out.
- `python` and `requirements` from the open-source Python plugin (`python/`)
- `kotlin`, `kotlinScript` and `kotlinGradleScript` from `plugins/kotlin/`

`NAME_dark.svg` is the variant for dark backgrounds; a few icons, such as
`gitignore`, have none.

## License

These icons are part of intellij-community's sources, licensed under the
Apache License 2.0 (most files say so in their header).  See `LICENSE.txt`
(Apache License 2.0) and `NOTICE.txt` (the repository's notice).
intellij-community's top-level `LICENSE.txt` now holds the terms for
JetBrains' binary builds, which do not apply to these source files.

Go, Rust and other commercial-plugin icons are not open source and are not
included.  Logos of languages and tools are trademarks of their owners.
