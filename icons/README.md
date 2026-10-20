# Icons

SVG icons from IntelliJ's New UI, copied unmodified by
[`../scripts/update-icons.sh`](../scripts/update-icons.sh) from the entries in
[`../scripts/manifest.txt`](../scripts/manifest.txt).  They come from two
places.

## intellij-community

From [JetBrains/intellij-community](https://github.com/JetBrains/intellij-community)
at the commit in [`../scripts/COMMIT`](../scripts/COMMIT):

- every icon in `platform/icons/src/expui/`: `fileTypes/NAME.svg` becomes
  `NAME.svg` here, and every other directory is kept (`nodes/`, `general/`,
  `actions/`, …).  Size variants (`NAME@20x20.svg`) are left out.
- `python` and `requirements` from the open-source Python plugin (`python/`)
- `kotlin`, `kotlinScript` and `kotlinGradleScript` from `plugins/kotlin/`

These icons are part of intellij-community's sources, licensed under the
Apache License 2.0 (most files say so in their header).  See `LICENSE.txt`
(Apache License 2.0) and `NOTICE.txt` (the repository's notice).
intellij-community's top-level `LICENSE.txt` now holds the terms for
JetBrains' binary builds, which do not apply to these source files.

## intellij-icons.jetbrains.design

File-type icons of JetBrains plugins whose sources are not public (Go, Rust,
Ruby, JavaScript, CLion, …), downloaded from
[IntelliJ Platform Icons](https://intellij-icons.jetbrains.design), the site
where JetBrains publishes the New UI icons for plugin developers to download.
Each `site:SET/SECTION/NAME` entry in the manifest is the file
`icons/SET/SECTION/NAME.svg` on the site (and its `_dark` variant, if any),
saved here as `NAME.svg`.  The site has no versions, so
[`../scripts/site.lock`](../scripts/site.lock) pins the SHA-256 of every
downloaded file.

The site states that its icons are licensed under the Apache License 2.0 and
says to check each SVG for the license header.  Some files carry that header:

- `ruby`, `erbFile`, `rbsFile`, `rackFile` (Ruby)
- `jsx`, `tsx`, `npm`, `yarn`, `eslint`, `prettier`, `stylelint`
  (JavaScript)
- `less`, `handlebars`, `freemarker`

The others have no header in the files the site serves:

- `go`, `goMod`, `goSum`, `goWork`, `goTemplate` (Go)
- `rustFile`, `cargoLock` (Rust)
- `dart`, `scalaScript`, `swiftPackageManifest`, `rMarkdownFile`
- `m`, `cu`, `cuh`, `asm`, `qml`, `CMake`, `makefile`, `meson` (CLion)
- `sass`, `stylus`, `haml`, `slim`

They are published on the same site, alongside the headed icons, for the same
purpose, and are included here on the understanding that the site's Apache
2.0 statement covers them too and that the header is simply missing.  If you
hold the rights to any of them and disagree, please open an issue and it will
be removed.

## Notes

`NAME_dark.svg` is the variant for dark backgrounds; a few icons, such as
`gitignore`, `sass` and `yarn`, have none.

Logos of languages and tools are trademarks of their owners.
