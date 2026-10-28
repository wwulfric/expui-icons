# expui-icons

[English](README.md) | 简体中文

![项目侧边栏（浅色、深色，彩色风格）与快速打开面板（单色风格）中的 expui-icons](docs/hero.png)

为 Emacs 提供 IntelliJ New UI 风格的图标。包含
[intellij-community](https://github.com/JetBrains/intellij-community) 平台的全部
`expui` 图标（含尺寸变体，涵盖文件类型、文件夹、代码元素、操作、工具窗口等），以及
JetBrains 各插件（Python、Kotlin、Go、Rust、Ruby、JavaScript、C/C++ 等）的文件类型图标。图标均为 SVG，带浅色和深色两种变体。可以按原设计的颜色绘制，
也可以绘制成单色，颜色跟随所在 face 的前景色。文件名、major mode 和 buffer 都能映射到
对应的文件类型图标。

本项目是独立项目，与 JetBrains 无隶属关系，也未获其背书。

## 环境要求

Emacs 29.1 及以上，且编译时启用了 SVG 支持（librsvg）。本包在 Emacs 31.1 上开发和测试，
并用 package-lint 按 29.1 检查过 API。在终端或不支持 SVG 的环境下，返回字符串的函数会
改为返回文本替代。

## 用法

```elisp
(require 'expui-icons)

;; 返回字符串，可直接 `insert' 或 `concat'，用法类似 nerd-icons：
(expui-icons-icon-for-file "main.py")
(expui-icons-icon-for-dir "~/src/.github/")
(expui-icons-icon-for-buffer (current-buffer) :face 'shadow)
(expui-icons-icon-for-mode 'emacs-lisp-mode :height 20)
(expui-icons-icon-for-extension "rs")
(expui-icons-icon "general/chevronRight")
(expui-icons-icon "nodes/class" :face 'font-lock-type-face)

;; 图标名与图片：
(expui-icons-name-for-file "Dockerfile")   ; => "docker"
(expui-icons-name-for-mode 'js-json-mode)  ; => "json"
(expui-icons-name-for-extension "PY")      ; => "python"
(expui-icons-name-for-buffer)              ; 依次看文件、Dired 目录、major mode
(expui-icons-image "python" :scale 2)      ; 图片描述符
(expui-icons-names)                        ; 全部可用图标
(expui-icons-names "nodes")                ; 某一类图标
```

图标名就是 `icons/` 下去掉 `.svg` 后缀的路径。文件类型图标直接用短名（`python`、
`anyType`）。其余图标（包括文件夹 `nodes/folder`）保留 IntelliJ 原有的目录，例如
`nodes/method`、`general/chevronDown`、`actions/addFile`、`toolwindows/project`。
从 0.2.2 起收录尺寸变体，并保留名称后缀：例如 `general/add@20x20` 使用上游的 20px 设计，
`diff/gutterCheckBox@14x14` 使用 14px gutter 复选框。
通过名称显式选择设计；`:height 20` 只缩放所选资源，不会切换到其他设计。
需要固定显示尺寸时，传入整数 `:height`。

返回字符串的函数接受 `:face` 参数，在 `mono` 风格下它决定图标颜色。也可以传
`:height`（像素）、`:scale` 等图片属性来覆盖默认值。图标在行内垂直居中
（`:ascent center`）。文件类型和 nodes 图标都是 16×16，显示高度恰好为
`expui-icons-height`（默认 16）像素。其他设计尺寸的图标（如 14px 的 gutter 图标、
28px 的对话框图标）按相同比例缩放。

### 与 nerd-icons 兼容

`expui-icons-icon-for-file`、`-icon-for-dir`、`-icon-for-extension`、
`-icon-for-mode` 的函数签名与 nerd-icons 中对应的函数相同，也接受相同的参数。为
nerd-icons 写的代码只要改函数名就能切换过来：

- `:face` 设置 face（在 `mono` 风格下也就是图标颜色）；
- 浮点数 `:height` 表示默认尺寸的倍数，对应 nerd-icons 中相对字体的高度
  （如 `:height 0.8`）；整数 `:height` 表示像素；
- 忽略 `:v-adjust`，因为图标总是垂直居中；
- 值为 nil 的参数表示"使用默认值"。

不同之处：图标是图片，所以终端里得到的是 `expui-icons-text-fallback` 而不是字形；
`icon-for-dir` 只看目录名，不访问文件系统（远程目录、符号链接目录、Git 仓库没有
专门的图标）；没有 `icon-for-url`；`expui-icons-icon-for-buffer` 是额外提供的。

### 选项

| 选项 | 说明 |
| --- | --- |
| `expui-icons-style` | `color`（原设计颜色）或 `mono`（使用 face 前景色），可用 `expui-icons-toggle-style` 切换 |
| `expui-icons-background` | `auto`、`light` 或 `dark`，决定 `color` 风格用哪种变体。`background-mode` 不总是准确，所以 `auto` 会检查默认 face 的背景色 |
| `expui-icons-height` | 16×16 图标的像素高度；设为 nil 则与其他图片一样按 `image-scaling-factor` 缩放 |
| `expui-icons-text-fallback` | 不支持 SVG 时使用的字符串，或以图标名为参数的函数 |
| `expui-icons-file-name-alist`、`expui-icons-directory-name-alist` | 按文件名匹配的正则（`Makefile`、`.github` 等），区分大小写 |
| `expui-icons-extension-alist` | 小写扩展名 |
| `expui-icons-mode-alist` | Major mode。先找精确匹配，再找第一个父 mode（`prog-mode` → `xml`，`text-mode` → `text`） |
| `expui-icons-mono-substitutes` | 在 `mono` 风格下替换的实心徽章图标，否则它们会变成色块 |

JetBrains 没有提供图标的语言（Emacs Lisp、Haskell、Lua、Clojure 等）使用通用的
`</>` 图标（`xml`）。

图片按图标名、风格、深浅变体和图片属性缓存。通过 Customize 或 `setopt` 修改选项会
清空缓存；`expui-icons-clear-cache` 还会重新读取修改过的 SVG 文件。

## 许可证

代码采用 Apache License 2.0（见 `LICENSE`）。图标同样采用 Apache 2.0，版权归
JetBrains s.r.o. 及贡献者所有。intellij-icons.jetbrains.design 上的部分图标（Go、Rust
等）文件里没有许可证头，为什么仍然收录见 [`icons/README.md`](icons/README.md)。
各语言和工具的标志仍是其所有者的商标。
