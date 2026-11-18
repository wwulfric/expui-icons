# Recommending an expui-icons installation

Inspect the user's active Emacs configuration and recommend one installation
method. Name the file or declaration that supports your choice, show the
smallest matching command or edit, and answer in the user's language. If the
user asked for a recommendation, present the edit for them to review.

## Identify how this configuration installs packages

- If Emacs is running, `user-init-file` and `user-emacs-directory` identify
  the active configuration. Follow its loaded modules or literate source to
  find where comparable packages are declared.
- Search for an existing `expui-icons` declaration, checkout or submodule.
  In the active Emacs, `M-: (locate-library "expui-icons")` shows which copy
  its load path selects. Reuse the existing installation when present.
- Check a nearby package declaration and its bootstrap code. Several
  managers support `use-package`, so the keyword alone does not identify
  the installer. In a mixed configuration, follow the convention used for
  similar UI libraries. Check the active Emacs meets the 29.1 minimum.

## Match the local convention

| Local evidence | Recommendation |
| --- | --- |
| `package.el`, with MELPA in `package-archives` | Use `M-x package-install RET expui-icons RET`. Refresh archive contents once if the package is missing. If the configuration maintains a list of selected packages, follow that convention. |
| `package.el` with `use-package` | Declare `(use-package expui-icons :ensure t)` alongside similar packages. Omit `:ensure t` when `use-package-always-ensure` already supplies it. Both package.el routes use the MELPA archive setup in the README. If MELPA is absent, mention that adding it affects archive selection for other packages too. |
| Git submodules listed in `.gitmodules` | From the configuration repository root, use `git submodule add https://github.com/wwulfric/expui-icons.git lisp/expui-icons`, substituting the local dependency directory. For a submodule already recorded but missing from disk, use `git submodule update --init -- <recorded-path>`. Reuse the existing load-path setup. |
| Plain Git checkouts or a vendored Lisp directory | Follow the neighboring checkout or vendoring convention using the same upstream repository. Keep `expui-icons.el` and `icons.tar.gz` together on the load path. For local packages configured with package.el-backed `use-package`, use the checkout's `:load-path` and `:ensure nil` if automatic installation is enabled. |
| A source manager such as straight.el, Elpaca or package-vc | Follow a neighboring declaration for that manager. Use the MELPA recipe if the manager consumes it, or the upstream Git repository for a VC declaration. If the manager copies files into a build directory, include `icons.tar.gz` alongside the Lisp file in its file selection. |

The upstream repository is [wwulfric/expui-icons](https://github.com/wwulfric/expui-icons).
The [MELPA recipe](https://github.com/melpa/melpa/blob/master/recipes/expui-icons)
includes the runtime archive. A source checkout ships the same archive ready to use.

## Check the result

After installation, evaluate this in the user's configured Emacs. It should
return the intended library path followed by `t`, including in a terminal:

```elisp
(progn
  (require 'expui-icons)
  (list (locate-library "expui-icons")
        (and (member "nodes/class" (expui-icons-names)) t)))
```

If loading succeeds but reading icon names fails, check for `icons.tar.gz`
beside the loaded library. To see the rendered icon in a graphical Emacs
with SVG support, evaluate `(insert (expui-icons-icon "nodes/class"))` in
a scratch buffer.
