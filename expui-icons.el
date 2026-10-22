;;; expui-icons.el --- Icons from IntelliJ's New UI -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Lufei Wang

;; Author: Lufei Wang <wwulfric@gmail.com>
;; Assisted-by: Claude:claude-opus-5-5
;; Version: 0.2.1
;; Package-Requires: ((emacs "29.1"))
;; Keywords: convenience, files
;; URL: https://github.com/wwulfric/expui-icons
;; SPDX-License-Identifier: Apache-2.0

;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;;; Commentary:

;; SVG file icons from IntelliJ's New UI, vendored unmodified under
;; icons/ (see icons/README.md for their origin and license).
;;
;; The API has two layers:
;;
;; - Names: `expui-icons-name-for-file', `expui-icons-name-for-extension',
;;   `expui-icons-name-for-mode' and `expui-icons-name-for-buffer' return
;;   an icon name such as "python".  `expui-icons-names' lists every
;;   available name.
;;
;; - Rendering: `expui-icons-image' returns an image descriptor, and
;;   `expui-icons-icon', `expui-icons-icon-for-file',
;;   `expui-icons-icon-for-dir', `expui-icons-icon-for-extension',
;;   `expui-icons-icon-for-mode' and `expui-icons-icon-for-buffer' return
;;   a string to `insert' or `concat':
;;
;;     (insert (expui-icons-icon-for-file "init.el") " init.el")
;;     (expui-icons-icon-for-buffer (current-buffer) :face 'shadow)
;;
;;   The icon-for functions match nerd-icons' and accept its arguments:
;;   `:face', a float `:height' relative to the default size, `:v-adjust'
;;   (ignored, since icons are centered) and nil values meaning "default".
;;
;; Two styles are available through `expui-icons-style':
;;
;; - `color' shows the original icons, using their dark variants on dark
;;   backgrounds (see `expui-icons-background').
;; - `mono' converts the icons while loading them: light fills are dropped
;;   and every other color becomes `currentColor', so an icon is drawn in
;;   the foreground of the face it is displayed with.  Solid badge icons,
;;   which would become plain blocks, are replaced as listed in
;;   `expui-icons-mono-substitutes'.
;;
;; Icon names are paths under icons/ without ".svg".  File-type icons have
;; plain names ("python", "anyType"); the rest of the New UI set mirrors
;; IntelliJ's directories: "nodes/folder", "nodes/class",
;; "general/chevronRight", "actions/search", and so on.
;;
;; Icons are centered on the line.  File-type and node icons are 16x16
;; and shown exactly `expui-icons-height' pixels high, so they line up in
;; columns; icons of other design sizes (14px gutter icons, 28px dialog
;; icons, ...) are scaled by the same factor.

;;; Code:

(require 'seq)

(defgroup expui-icons nil
  "File icons from IntelliJ's New UI."
  :group 'appearance
  :prefix "expui-icons-")

(defconst expui-icons-directory
  (expand-file-name "icons/"
                    (file-name-directory (or (macroexp-file-name)
                                             buffer-file-name)))
  "Directory holding the vendored SVG icons.")

(defvar expui-icons--cache (make-hash-table :test #'equal)
  "Image descriptors keyed by everything that changes the image.")

(defun expui-icons--set-and-clear (symbol value)
  "Set SYMBOL to VALUE and forget images that depend on it."
  (set-default-toplevel-value symbol value)
  (clrhash expui-icons--cache))

(defcustom expui-icons-style 'color
  "How icons are drawn.
`color' shows the icons as designed.  `mono' draws them in the
foreground color of the face they are displayed with."
  :type '(choice (const :tag "As designed" color)
                 (const :tag "In the face's foreground" mono))
  :set #'expui-icons--set-and-clear)

(defcustom expui-icons-background 'auto
  "Background the `color' icons are designed for.
`auto' looks at the default face's background, falling back to the
frame's `background-mode'.  `light' and `dark' force the variant."
  :type '(choice (const auto) (const light) (const dark))
  :set #'expui-icons--set-and-clear)

(defcustom expui-icons-height 16
  "Pixel height of a 16x16 icon, or nil to scale icons as images are.
Icons of other design sizes are scaled by the same factor.  With a
number the icons ignore `image-scaling-factor', so their size is known
exactly.  Individual calls can pass `:height', `:width' or `:scale'."
  :type '(choice (natnum :tag "Pixels")
                 (const :tag "Scale like other images" nil))
  :set #'expui-icons--set-and-clear)

(defcustom expui-icons-text-fallback ""
  "Text returned instead of an icon when images cannot be displayed.
Either a string or a function called with the icon name."
  :type '(choice string function))

(defcustom expui-icons-default "anyType"
  "Icon for files that match no mapping."
  :type 'string)

(defcustom expui-icons-directory-default "nodes/folder"
  "Icon for directories that match no mapping."
  :type 'string)

(defcustom expui-icons-buffer-default "text"
  "Icon for buffers that visit no file and whose mode is not mapped."
  :type 'string)

(defcustom expui-icons-file-name-alist
  `(("\\`\\(?:GNU\\)?[Mm]akefile\\'" . "makefile")
    ("\\`CMakeLists\\.txt\\'" . "CMake")
    ("\\`meson\\(?:\\.build\\|_options\\.txt\\|\\.options\\)\\'" . "meson")
    ("\\`go\\.mod\\'" . "goMod")
    ("\\`go\\.sum\\'" . "goSum")
    ("\\`go\\.work\\(?:\\.sum\\)?\\'" . "goWork")
    ("\\`Cargo\\.lock\\'" . "cargoLock")
    (,(concat "\\`" (regexp-opt '("Gemfile" "Gemfile.lock" "Rakefile"
                                  "Guardfile" "Capfile" "Brewfile"
                                  "Podfile" "Vagrantfile"))
              "\\'")
     . "ruby")
    ("\\`Package\\.swift\\'" . "swiftPackageManifest")
    ("\\`\\(?:package\\(?:-lock\\)?\\.json\\|\\.npmrc\\)\\'" . "npm")
    ("\\`\\(?:yarn\\.lock\\|\\.yarnrc\\(?:\\.ya?ml\\)?\\)\\'" . "yarn")
    ("\\`\\(?:\\.eslintrc\\(?:\\..*\\)?\\|eslint\\.config\\..*\\|\\.eslintignore\\)\\'"
     . "eslint")
    ("\\`\\(?:\\.prettierrc\\(?:\\..*\\)?\\|prettier\\.config\\..*\\|\\.prettierignore\\)\\'"
     . "prettier")
    ("\\`\\(?:\\.stylelintrc\\(?:\\..*\\)?\\|stylelint\\.config\\..*\\)\\'"
     . "stylelint")
    ("\\`\\(?:.*\\.\\)?\\(?:[Dd]ockerfile\\|Containerfile\\)\\'" . "docker")
    ("\\`docker-compose.*\\.ya?ml\\'" . "docker")
    ("\\`\\.\\(?:git\\|docker\\|npm\\|hg\\)ignore\\'" . "gitignore")
    ("\\`\\.git\\(?:attributes\\|modules\\|config\\)\\'" . "config")
    ("\\`\\.editorconfig\\'" . "editorConfig")
    ("\\`\\.dir-locals\\(?:-2\\)?\\.el\\'" . "config")
    ("\\`\\.env\\(?:\\..*\\)?\\'" . "config")
    ("\\`Jenkinsfile\\'" . "jenkins")
    ("\\`\\(?:BUILD\\|WORKSPACE\\|MODULE\\)\\(?:\\.bazel\\)?\\'" . "bazel")
    ("\\`\\(?:settings\\|build\\)\\.gradle\\.kts\\'" . "kotlinGradleScript")
    ("\\`requirements.*\\.txt\\'" . "requirements")
    ("\\`MANIFEST\\.MF\\'" . "manifest")
    (,(concat "\\`" (regexp-opt '("LICENSE" "LICENCE" "COPYING" "NOTICE"
                                  "AUTHORS" "CHANGELOG"))
              "\\(?:\\.txt\\)?\\'")
     . "text"))
  "Regexps matched against a file's base name, before its extension.
Matching is case-sensitive."
  :type '(alist :key-type regexp :value-type string))

(defcustom expui-icons-directory-name-alist
  '(("\\`\\.github\\'" . "nodes/folderGithub")
    ("\\`node_modules\\'" . "nodes/libraryFolder")
    ("\\`logs?\\'" . "nodes/logFolder"))
  "Regexps matched against a directory's base name.
Matching is case-sensitive."
  :type '(alist :key-type regexp :value-type string))

(defmacro expui-icons--alist (&rest groups)
  "Expand GROUPS of (ICON KEY...) into an alist of (KEY . ICON)."
  `(quote ,(mapcan (lambda (group)
                     (mapcar (lambda (ext) (cons ext (car group)))
                             (cdr group)))
                   groups)))

(defcustom expui-icons-extension-alist
  (expui-icons--alist
   ;; IntelliJ has no icons for these languages; use its generic `</>'.
   ("xml" "xml" "el" "eld" "hs" "lhs" "lua" "scm" "ss" "rkt"
    "clj" "cljs" "cljc" "edn" "ml" "mli" "ex" "exs" "erl" "hrl" "nix" "zig"
    "jl" "r" "nim" "elm" "fs" "fsx" "purs" "agda" "idr" "v" "sv"
    "wat" "proto" "plist" "xsl" "xslt" "svelte" "astro")
   ("python" "py" "pyi" "pyw" "pyx")
   ("kotlin" "kt")
   ("kotlinScript" "kts")
   ("go" "go")
   ("goTemplate" "gotmpl")
   ("rustFile" "rs")
   ("ruby" "rb" "rbw" "rake" "gemspec")
   ("erbFile" "erb")
   ("rbsFile" "rbs")
   ("rackFile" "ru")
   ("dart" "dart")
   ("rMarkdownFile" "rmd")
   ;; Not "m", which is also MATLAB/Octave; `objc-mode' maps it below.
   ("m" "mm")
   ("cu" "cu")
   ("cuh" "cuh")
   ("asm" "asm" "s" "nasm")
   ("qml" "qml")
   ("CMake" "cmake")
   ("makefile" "mk" "mak")
   ("javaScript" "js" "mjs" "cjs")
   ("jsx" "jsx")
   ("typeScript" "ts" "mts" "cts")
   ("tsx" "tsx")
   ("shell" "sh" "bash" "zsh" "fish" "ksh" "csh" "command")
   ("microsoftWindows" "bat" "cmd" "ps1" "psm1" "exe" "dll" "msi")
   ("markdown" "md" "markdown" "mdx")
   ("text" "txt" "org" "tex" "log" "texi" "info")
   ("rst" "rst")
   ("yaml" "yaml" "yml")
   ("config" "ini" "conf" "cfg" "cabal" "env" "service" "desktop" "lock")
   ("csv" "csv" "tsv")
   ("image" "png" "jpg" "jpeg" "gif" "svg" "webp" "ico" "bmp" "tif" "tiff"
    "heic" "avif" "icns" "xpm" "pbm")
   ("font" "ttf" "otf" "woff" "woff2" "eot")
   ("archive" "zip" "gz" "tgz" "tar" "xz" "bz2" "zst" "7z" "rar" "jar" "war"
    "ear" "whl" "deb" "rpm" "dmg")
   ("binaryData" "bin" "dat" "o" "a" "so" "dylib" "elc" "eln" "pyc" "wasm")
   ("html" "html" "htm")
   ("xhtml" "xhtml")
   ("css" "css")
   ("sass" "scss" "sass")
   ("less" "less")
   ("stylus" "styl")
   ("haml" "haml")
   ("slim" "slim")
   ("handlebars" "hbs" "handlebars" "mustache")
   ("freemarker" "ftl" "ftlh")
   ("c" "c")
   ("h" "h")
   ("cpp" "cpp" "cc" "cxx" "c++" "hpp" "hh" "hxx" "ino")
   ("Csharp" "cs" "csx")
   ("java" "java")
   ("javaClass" "class")
   ("groovy" "groovy" "gvy")
   ("gradle" "gradle")
   ("language/scala" "scala" "sbt")
   ("scalaScript" "sc")
   ("language/php" "php" "phtml")
   ("perl" "pl" "pm" "t" "pod")
   ("swiftLang" "swift")
   ("sql" "sql" "ddl")
   ("json" "json" "jsonc" "json5" "jsonl" "ndjson" "geojson")
   ("toml" "toml")
   ("properties" "properties")
   ("patch" "patch" "diff")
   ("graphql" "graphql" "gql")
   ("terraform" "tf" "tfvars" "hcl")
   ("jupyter" "ipynb")
   ("vue" "vue")
   ("http" "http" "rest")
   ("regexp" "regexp")
   ("sourceMap" "map")
   ("xsd" "xsd")
   ("wsdl" "wsdl")
   ("jsp" "jsp")
   ("jspx" "jspx")
   ("idl" "idl")
   ("hprof" "hprof")
   ("jfr" "jfr")
   ("uiForm" "form")
   ("i18n" "po" "pot" "mo" "xliff"))
  "Lowercase file extensions mapped to icon names."
  :type '(alist :key-type string :value-type string))

(defcustom expui-icons-mode-alist
  (expui-icons--alist
   ("nodes/folder" dired-mode wdired-mode)
   ("python" python-base-mode python-mode)
   ("kotlin" kotlin-mode kotlin-ts-mode)
   ("json" js-json-mode json-mode json-ts-mode)
   ("tsx" tsx-ts-mode)
   ("typeScript" typescript-ts-base-mode typescript-mode)
   ("jsx" js-jsx-mode rjsx-mode)
   ("javaScript" js-base-mode js-mode js2-mode)
   ("sass" scss-mode sass-mode)
   ("less" less-css-mode)
   ("stylus" stylus-mode)
   ("css" css-base-mode css-mode)
   ("html" mhtml-mode html-mode html-ts-mode)
   ("haml" haml-mode)
   ("slim" slim-mode)
   ("handlebars" handlebars-mode)
   ("makefile" makefile-mode)
   ("CMake" cmake-mode cmake-ts-mode)
   ("meson" meson-mode)
   ("shell" sh-base-mode sh-mode fish-mode
    eshell-mode shell-mode term-mode vterm-mode eat-mode)
   ("goMod" go-mod-ts-mode go-dot-mod-mode)
   ("goWork" go-work-ts-mode)
   ("go" go-mode go-ts-mode)
   ("rustFile" rust-mode rust-ts-mode rustic-mode)
   ("ruby" ruby-base-mode ruby-mode ruby-ts-mode enh-ruby-mode)
   ("dart" dart-mode dart-ts-mode)
   ("asm" asm-mode nasm-mode)
   ("qml" qml-mode qml-ts-mode)
   ("markdown" markdown-mode markdown-ts-mode gfm-mode)
   ("rst" rst-mode)
   ("yaml" yaml-mode yaml-ts-mode)
   ("toml" conf-toml-mode toml-ts-mode)
   ("properties" conf-javaprop-mode)
   ("config" conf-mode)
   ("sql" sql-mode)
   ("c" c-ts-mode c-mode)
   ("m" objc-mode)
   ("cu" cuda-mode cuda-ts-mode)
   ("cpp" c++-ts-mode c++-mode)
   ("Csharp" csharp-mode csharp-ts-mode)
   ("java" java-mode java-ts-mode)
   ("groovy" groovy-mode)
   ("language/scala" scala-mode scala-ts-mode)
   ("language/php" php-mode php-ts-mode)
   ("perl" perl-mode cperl-mode)
   ("swiftLang" swift-mode)
   ("docker" dockerfile-mode dockerfile-ts-mode)
   ("terraform" terraform-mode hcl-mode)
   ("graphql" graphql-mode)
   ("vue" vue-mode)
   ("patch" diff-mode)
   ("image" image-mode)
   ("archive" archive-mode tar-mode)
   ("binaryData" hexl-mode)
   ("xml" nxml-mode prog-mode)
   ("text" text-mode))
  "Major modes mapped to icon names.
A mode listed here exactly wins; otherwise the first entry the mode
derives from is used, so list more specific modes first."
  :type '(alist :key-type symbol :value-type string))

(defcustom expui-icons-mono-substitutes
  '(("javaScript" . "xml") ("typeScript" . "xml") ("swiftLang" . "xml")
    ("css" . "xml") ("sass" . "xml") ("npm" . "json")
    ("go" . "xml") ("goTemplate" . "xml") ("dart" . "xml")
    ("goMod" . "config") ("goWork" . "config") ("goSum" . "text")
    ("docker" . "config") ("jenkins" . "config")
    ("gitignore" . "anyType"))
  "Icons replaced in the `mono' style.
These are solid badges, which become featureless blocks in one color."
  :type '(alist :key-type string :value-type string)
  :set #'expui-icons--set-and-clear)

;;;; Names

(defun expui-icons--match (alist name)
  "Return the icon of the first regexp in ALIST matching NAME."
  (let ((case-fold-search nil))
    (cdr (seq-find (lambda (entry) (string-match-p (car entry) name))
                   alist))))

(defun expui-icons-name-for-file (file &optional directory)
  "Return the icon name for FILE, a directory if DIRECTORY is non-nil.
FILE is a file name; only its base name is examined and the file need
not exist.  A FILE ending in a slash also counts as a directory."
  (let ((base (file-name-nondirectory (directory-file-name file))))
    (if (or directory (directory-name-p file))
        (or (expui-icons--match expui-icons-directory-name-alist base)
            expui-icons-directory-default)
      (or (expui-icons--match expui-icons-file-name-alist base)
          (when-let* ((ext (file-name-extension base)))
            (expui-icons-name-for-extension ext))
          expui-icons-default))))

(defun expui-icons-name-for-extension (extension)
  "Return the icon name for file EXTENSION (without the dot), or nil."
  (cdr (assoc (downcase extension) expui-icons-extension-alist)))

(defun expui-icons-name-for-mode (mode)
  "Return the icon name for major MODE, or nil if it is not mapped."
  (or (cdr (assq mode expui-icons-mode-alist))
      (cdr (seq-find (lambda (entry) (provided-mode-derived-p mode (car entry)))
                     expui-icons-mode-alist))))

(defun expui-icons-name-for-buffer (&optional buffer)
  "Return the icon name for BUFFER, which defaults to the current buffer.
A buffer visiting a file uses the file's icon, a Dired buffer that of
its directory, and any other buffer that of its major mode."
  (with-current-buffer (or buffer (current-buffer))
    (cond (buffer-file-name (expui-icons-name-for-file buffer-file-name))
          ((derived-mode-p 'dired-mode 'wdired-mode)
           (expui-icons-name-for-file default-directory t))
          (t (or (expui-icons-name-for-mode major-mode)
                 expui-icons-buffer-default)))))

(defun expui-icons-names (&optional category)
  "Return the names of all available icons, sorted.
With CATEGORY, a directory such as \"nodes\" or \"actions\", return only
the icons in it; the empty string selects the file-type icons."
  (let ((root (expand-file-name (or category "") expui-icons-directory)))
    (sort (mapcar (lambda (file)
                    (file-name-sans-extension
                     (file-relative-name file expui-icons-directory)))
                  (seq-remove (lambda (file)
                                (string-suffix-p "_dark.svg" file))
                              (if (equal category "")
                                  (directory-files root t "\\.svg\\'")
                                (directory-files-recursively
                                 root "\\.svg\\'"))))
          #'string<)))

;;;; SVG loading

(defun expui-icons--light-color-p (color)
  "Return non-nil if the SVG COLOR is a light tint.
Only white and #RRGGBB/#RGB colors are recognized."
  (pcase (downcase color)
    ((or "white" "#fff" "#ffffff") t)
    ((rx bos "#" (let r (= 2 xdigit)) (let g (= 2 xdigit)) (let b (= 2 xdigit))
         eos)
     (let ((channel (lambda (hex) (/ (string-to-number hex 16) 255.0))))
       ;; Relative luminance (sRGB coefficients, without linearization).
       (> (+ (* 0.2126 (funcall channel r))
             (* 0.7152 (funcall channel g))
             (* 0.0722 (funcall channel b)))
          0.8)))))

(defun expui-icons--monochrome (svg)
  "Return SVG with light fills removed and other colors as `currentColor'."
  (replace-regexp-in-string
   "\\(fill\\|stroke\\)=\"\\([^\"]+\\)\""
   (lambda (match)
     (let ((attribute (match-string 1 match))
           (color (match-string 2 match)))
       (cond ((member color '("none" "currentColor")) match)
             ;; `replace-regexp-in-string' substitutes using the match data
             ;; of this match; the color test must not clobber it.
             ((and (equal attribute "fill")
                   (save-match-data (expui-icons--light-color-p color)))
              "fill=\"none\"")
             (t (format "%s=\"currentColor\"" attribute)))))
   svg t t))

(defun expui-icons--dark-p ()
  "Return non-nil if the `color' icons should use their dark variants."
  (pcase expui-icons-background
    ('dark t)
    ('light nil)
    ;; `background-mode' can disagree with the theme, so prefer the color.
    (_ (if-let* ((background (face-background 'default nil t))
                 (values (color-values background)))
           (color-dark-p (mapcar (lambda (value) (/ value 65535.0)) values))
         (eq (frame-parameter nil 'background-mode) 'dark)))))

(defun expui-icons--file (name &optional dark)
  "Return the SVG file of icon NAME, preferring its dark variant if DARK.
Unknown names fall back to `expui-icons-default'."
  (let ((file (lambda (base) (expand-file-name (concat base ".svg")
                                               expui-icons-directory))))
    (seq-find #'file-exists-p
              (delq nil (list (and dark (funcall file (concat name "_dark")))
                              (funcall file name)
                              (funcall file expui-icons-default))))))

(defun expui-icons--resolve (name)
  "Return the icon actually drawn for NAME in the current style."
  (if (eq expui-icons-style 'mono)
      (or (cdr (assoc name expui-icons-mono-substitutes)) name)
    name))

(defun expui-icons--image-props (props)
  "Return image properties for PROPS, an `expui-icons-image' plist.
As in nerd-icons, properties with nil values are ignored, `:v-adjust' is
dropped (icons are centered), and a float `:height' is a factor of the
default icon size; an integer `:height' or `:width' is in pixels."
  (let (result (factor 1))
    (while props
      (let ((key (car props))
            (value (cadr props)))
        (cond ((or (null value) (eq key :v-adjust)))
              ((and (eq key :height) (floatp value)) (setq factor value))
              (t (setq result (plist-put result key value)))))
      (setq props (cddr props)))
    (let ((scale (* factor (or (plist-get result :scale) 1))))
      (cond
       ;; An explicit size is exact pixels unless the caller also scales.
       ((or (plist-member result :height) (plist-member result :width))
        (setq result (plist-put result :scale scale)))
       ;; Otherwise scale the design size so that 16px becomes the height.
       (expui-icons-height
        (setq result (plist-put result :scale
                                (* scale (/ expui-icons-height 16.0)))))
       ((/= scale 1)
        (setq result (plist-put result :scale scale)))))
    (unless (plist-member result :ascent)
      (setq result (plist-put result :ascent 'center)))
    result))

(defun expui-icons-svg-p ()
  "Return non-nil if the selected frame can display the SVG icons."
  (and (display-images-p) (image-type-available-p 'svg)))

(defun expui-icons-image (name &rest props)
  "Return an image descriptor for icon NAME in `expui-icons-style'.
PROPS are image properties, e.g. `:height' (integer pixels, or a float
factor of the default size as in nerd-icons) or `:scale', which override
the defaults.  In the `mono' style the image is drawn in the
foreground of the face it is displayed with.  Return nil if Emacs has no
SVG support."
  (when (image-type-available-p 'svg)
    (let* ((name (expui-icons--resolve name))
           (dark (and (eq expui-icons-style 'color) (expui-icons--dark-p)))
           (props (expui-icons--image-props props))
           (key (list name expui-icons-style dark props)))
      (or (gethash key expui-icons--cache)
          (puthash key
                   (if (eq expui-icons-style 'mono)
                       (apply #'create-image
                              (expui-icons--monochrome
                               (with-temp-buffer
                                 (insert-file-contents (expui-icons--file name))
                                 (buffer-string)))
                              'svg t props)
                     (apply #'create-image (expui-icons--file name dark)
                            'svg nil props))
                   expui-icons--cache)))))

;;;; Strings

(defun expui-icons--fallback (name face)
  "Return the text fallback for icon NAME, in FACE if non-nil."
  (let ((text (if (functionp expui-icons-text-fallback)
                  (funcall expui-icons-text-fallback name)
                expui-icons-text-fallback)))
    (if (and face (not (equal text "")))
        (propertize text 'face face)
      text)))

(defun expui-icons-icon (name &rest props)
  "Return a string displaying icon NAME, to `insert' or `concat'.
PROPS may contain `:face', the face of the string; in the `mono' style
its foreground colors the icon.  Other PROPS are image properties as for
`expui-icons-image'.  When the selected frame cannot display SVG images,
return `expui-icons-text-fallback' instead."
  (let ((face (plist-get props :face))
        (image-props (expui-icons--plist-without props :face)))
    (if (expui-icons-svg-p)
        (apply #'propertize " "
               'display (apply #'expui-icons-image name image-props)
               (and face (list 'face face)))
      (expui-icons--fallback name face))))

(defun expui-icons--plist-without (plist &rest keys)
  "Return a copy of PLIST without KEYS."
  (let (result)
    (while plist
      (unless (memq (car plist) keys)
        (setq result (cons (cadr plist) (cons (car plist) result))))
      (setq plist (cddr plist)))
    (nreverse result)))

(defun expui-icons-icon-for-file (file &rest props)
  "Return a string displaying the icon for FILE.
PROPS are as for `expui-icons-icon'; a non-nil `:directory' treats FILE
as a directory, as does a trailing slash."
  (apply #'expui-icons-icon
         (expui-icons-name-for-file file (plist-get props :directory))
         (expui-icons--plist-without props :directory)))

(defun expui-icons-icon-for-dir (directory &rest props)
  "Return a string displaying the icon for DIRECTORY.
DIRECTORY defaults to `default-directory'; only its name is examined.
PROPS are as for `expui-icons-icon'."
  (apply #'expui-icons-icon
         (expui-icons-name-for-file (or directory default-directory) t)
         props))

(defun expui-icons-icon-for-extension (extension &rest props)
  "Return a string displaying the icon for file EXTENSION.
Unmapped extensions use `expui-icons-default'.  PROPS are as for
`expui-icons-icon'."
  (apply #'expui-icons-icon
         (or (expui-icons-name-for-extension extension) expui-icons-default)
         props))

(defun expui-icons-icon-for-mode (mode &rest props)
  "Return a string displaying the icon for major MODE.
Unmapped modes use `expui-icons-buffer-default'.  PROPS are as for
`expui-icons-icon'."
  (apply #'expui-icons-icon
         (or (expui-icons-name-for-mode mode) expui-icons-buffer-default)
         props))

(defun expui-icons-icon-for-buffer (&optional buffer &rest props)
  "Return a string displaying the icon for BUFFER (default: current).
PROPS are as for `expui-icons-icon'."
  (apply #'expui-icons-icon (expui-icons-name-for-buffer buffer) props))

;;;; Commands

(defun expui-icons-toggle-style ()
  "Switch `expui-icons-style' between `color' and `mono'."
  (interactive)
  (customize-set-variable 'expui-icons-style
                          (if (eq expui-icons-style 'color) 'mono 'color))
  (force-mode-line-update t)
  (message "expui-icons style: %s" expui-icons-style))

(defun expui-icons-clear-cache ()
  "Forget loaded icons, e.g. after editing the SVG files."
  (interactive)
  (clrhash expui-icons--cache)
  (clear-image-cache))

(provide 'expui-icons)
;;; expui-icons.el ends here
