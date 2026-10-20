;;; expui-icons-test.el --- Tests for expui-icons -*- lexical-binding: t; -*-

;; SPDX-License-Identifier: Apache-2.0

;;; Commentary:

;; Run with: emacs -Q --batch -L . -l test/expui-icons-test.el \
;;             -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'expui-icons)
(require 'make-mode)
(require 'org)
(require 'wdired)

(defmacro expui-icons-test--with-clean-state (&rest body)
  "Run BODY with default settings and an empty cache."
  (declare (indent 0) (debug t))
  `(let ((expui-icons-style 'color)
         (expui-icons-background 'light)
         (expui-icons-height 16)
         (expui-icons-text-fallback "")
         (expui-icons--cache (make-hash-table :test #'equal)))
     ,@body))

;;;; Names

(ert-deftest expui-icons-test-name-for-file ()
  (should (equal (expui-icons-name-for-file "/a/b/init.el") "xml"))
  (should (equal (expui-icons-name-for-file "main.py") "python"))
  (should (equal (expui-icons-name-for-file "README.MD") "markdown"))
  (should (equal (expui-icons-name-for-file "build.gradle.kts")
                 "kotlinGradleScript"))
  (should (equal (expui-icons-name-for-file "script.kts") "kotlinScript"))
  (should (equal (expui-icons-name-for-file "Makefile") "makefile"))
  (should (equal (expui-icons-name-for-file "CMakeLists.txt") "CMake"))
  (should (equal (expui-icons-name-for-file "go.mod") "goMod"))
  (should (equal (expui-icons-name-for-file "go.work.sum") "goWork"))
  (should (equal (expui-icons-name-for-file "Cargo.lock") "cargoLock"))
  (should (equal (expui-icons-name-for-file "Cargo.toml") "toml"))
  (should (equal (expui-icons-name-for-file "Gemfile") "ruby"))
  (should (equal (expui-icons-name-for-file "package.json") "npm"))
  (should (equal (expui-icons-name-for-file "tsconfig.json") "json"))
  (should (equal (expui-icons-name-for-file ".eslintrc.json") "eslint"))
  (should (equal (expui-icons-name-for-file "prettier.config.js") "prettier"))
  (should (equal (expui-icons-name-for-file "Dockerfile") "docker"))
  (should (equal (expui-icons-name-for-file "app.Dockerfile") "docker"))
  (should (equal (expui-icons-name-for-file ".gitignore") "gitignore"))
  (should (equal (expui-icons-name-for-file ".editorconfig") "editorConfig"))
  (should (equal (expui-icons-name-for-file "LICENSE") "text"))
  (should (equal (expui-icons-name-for-file "license") "anyType"))
  (should (equal (expui-icons-name-for-file "requirements-dev.txt")
                 "requirements"))
  (should (equal (expui-icons-name-for-file "no-extension") "anyType"))
  (should (equal (expui-icons-name-for-file "file.unknownext") "anyType")))

(ert-deftest expui-icons-test-name-for-extension ()
  (should (equal (expui-icons-name-for-extension "py") "python"))
  (should (equal (expui-icons-name-for-extension "PY") "python"))
  (should (equal (expui-icons-name-for-extension "go") "go"))
  (should (equal (expui-icons-name-for-extension "rs") "rustFile"))
  (should (equal (expui-icons-name-for-extension "rb") "ruby"))
  (should (equal (expui-icons-name-for-extension "dart") "dart"))
  (should (equal (expui-icons-name-for-extension "jsx") "jsx"))
  (should (equal (expui-icons-name-for-extension "scss") "sass"))
  (should-not (expui-icons-name-for-extension "unknownext")))

(ert-deftest expui-icons-test-name-for-directory ()
  (should (equal (expui-icons-name-for-file "/repo/src" t) "nodes/folder"))
  (should (equal (expui-icons-name-for-file "/repo/src/") "nodes/folder"))
  (should (equal (expui-icons-name-for-file "/repo/.github" t)
                 "nodes/folderGithub"))
  (should (equal (expui-icons-name-for-file "/repo/.github/")
                 "nodes/folderGithub"))
  (should (equal (expui-icons-name-for-file "node_modules" t)
                 "nodes/libraryFolder"))
  ;; File-name rules do not apply to directories.
  (should (equal (expui-icons-name-for-file "Makefile" t) "nodes/folder")))

(ert-deftest expui-icons-test-name-for-mode ()
  (should (equal (expui-icons-name-for-mode 'python-mode) "python"))
  ;; An exact entry wins over an earlier one the mode derives from.
  (should (equal (expui-icons-name-for-mode 'js-json-mode) "json"))
  (should (equal (expui-icons-name-for-mode 'js-mode) "javaScript"))
  (should (equal (expui-icons-name-for-mode 'js-jsx-mode) "jsx"))
  (should (equal (expui-icons-name-for-mode 'scss-mode) "sass"))
  (should (equal (expui-icons-name-for-mode 'ruby-mode) "ruby"))
  ;; Modes derived from makefile-mode.
  (should (equal (expui-icons-name-for-mode 'makefile-gmake-mode) "makefile"))
  ;; Derived fallbacks.
  (should (equal (expui-icons-name-for-mode 'emacs-lisp-mode) "xml"))
  (should (equal (expui-icons-name-for-mode 'org-mode) "text"))
  (should (equal (expui-icons-name-for-mode 'wdired-mode) "nodes/folder"))
  (should-not (expui-icons-name-for-mode 'fundamental-mode)))

(ert-deftest expui-icons-test-name-for-buffer ()
  (with-temp-buffer
    (setq buffer-file-name "/tmp/expui/notes.toml")
    (should (equal (expui-icons-name-for-buffer) "toml")))
  (with-temp-buffer
    (emacs-lisp-mode)
    (should (equal (expui-icons-name-for-buffer (current-buffer)) "xml")))
  (with-temp-buffer
    (should (equal (expui-icons-name-for-buffer) expui-icons-buffer-default))))

(defun expui-icons-test--mapped-icons ()
  "Return every icon name the default mappings can produce."
  (delete-dups
   (append (list expui-icons-default
                 expui-icons-directory-default
                 expui-icons-buffer-default)
           (mapcar #'cdr expui-icons-file-name-alist)
           (mapcar #'cdr expui-icons-directory-name-alist)
           (mapcar #'cdr expui-icons-extension-alist)
           (mapcar #'cdr expui-icons-mode-alist)
           (mapcar #'car expui-icons-mono-substitutes)
           (mapcar #'cdr expui-icons-mono-substitutes))))

(ert-deftest expui-icons-test-names ()
  (let ((names (expui-icons-names)))
    ;; The whole New UI platform set plus the plugin file types.
    (should (> (length names) 800))
    (dolist (name '("python" "anyType" "nodes/folder" "nodes/class"
                    "general/chevronRight" "general/search" "actions/addFile"
                    "language/scala"))
      (should (member name names)))
    (should-not (seq-find (lambda (name) (string-suffix-p "_dark" name))
                          names)))
  (let ((file-types (expui-icons-names "")))
    (should (member "python" file-types))
    (should-not (member "nodes/folder" file-types)))
  (should (equal (expui-icons-names "nodes")
                 (seq-filter (lambda (name) (string-prefix-p "nodes/" name))
                             (expui-icons-names)))))

(ert-deftest expui-icons-test-mapped-icons-exist ()
  (let ((names (expui-icons-names)))
    (dolist (name (expui-icons-test--mapped-icons))
      (should (member name names)))))

(ert-deftest expui-icons-test-mapped-icons-are-16px ()
  ;; File icons must share one size to line up in columns.
  (dolist (name (append '("general/chevronRight" "general/chevronDown")
                        (expui-icons-test--mapped-icons)))
    (dolist (dark '(nil t))
      (with-temp-buffer
        (insert-file-contents (expui-icons--file name dark))
        (should (search-forward "viewBox=\"0 0 16 16\"" nil t))))))

;;;; Monochrome conversion

(ert-deftest expui-icons-test-light-color-p ()
  (should (expui-icons--light-color-p "white"))
  (should (expui-icons--light-color-p "#FFF"))
  (should (expui-icons--light-color-p "#EBECF0"))
  (should-not (expui-icons--light-color-p "#3574F0"))
  (should-not (expui-icons--light-color-p "#6C707E"))
  (should-not (expui-icons--light-color-p "url(#gradient)")))

(ert-deftest expui-icons-test-monochrome ()
  (should (equal (expui-icons--monochrome
                  "<path fill=\"#EBECF0\" stroke=\"#6C707E\"/>")
                 "<path fill=\"none\" stroke=\"currentColor\"/>"))
  (should (equal (expui-icons--monochrome "<g fill=\"none\"/>")
                 "<g fill=\"none\"/>"))
  (should (equal (expui-icons--monochrome "<g fill=\"currentColor\"/>")
                 "<g fill=\"currentColor\"/>")))

(ert-deftest expui-icons-test-monochrome-keeps-match-data ()
  ;; Regression: testing the color clobbered the match data used for the
  ;; replacement, leaving fragments like fill="currentColor"3574F0".
  (let ((svg (concat "<svg><path fill=\"#FFFFFF\" d=\"M1 1\"/>"
                     "<path fill=\"#3574F0\" d=\"M2 2\"/>"
                     "<path stroke=\"#FFAF0F\"/></svg>")))
    (should (equal (expui-icons--monochrome svg)
                   (concat "<svg><path fill=\"none\" d=\"M1 1\"/>"
                           "<path fill=\"currentColor\" d=\"M2 2\"/>"
                           "<path stroke=\"currentColor\"/></svg>")))))

(ert-deftest expui-icons-test-monochrome-vendored-icons ()
  (dolist (name (expui-icons-names))
    (let ((svg (with-temp-buffer
                 (insert-file-contents (expui-icons--file name))
                 (buffer-string))))
      (should-not (string-match-p "\\(?:fill\\|stroke\\)=\"#"
                                  (expui-icons--monochrome svg)))
      (should-not (string-match-p "currentColor\"[^ \t\n/>]"
                                  (expui-icons--monochrome svg))))))

;;;; Images and cache

(ert-deftest expui-icons-test-image-props ()
  (expui-icons-test--with-clean-state
    (should (equal (expui-icons--image-props nil)
                   '(:scale 1.0 :ascent center)))
    (should (equal (expui-icons--image-props '(:height 20))
                   '(:height 20 :scale 1 :ascent center)))
    (should (equal (expui-icons--image-props '(:height 20 :scale 2))
                   '(:height 20 :scale 2 :ascent center)))
    (should (equal (expui-icons--image-props '(:scale 2))
                   '(:scale 2.0 :ascent center)))
    (should (equal (expui-icons--image-props '(:ascent 80))
                   '(:ascent 80 :scale 1.0)))
    (let ((expui-icons-height 24))
      (should (equal (expui-icons--image-props nil)
                     '(:scale 1.5 :ascent center))))))

(ert-deftest expui-icons-test-nerd-icons-props ()
  (expui-icons-test--with-clean-state
    ;; nil values mean "default"; :v-adjust is dropped.
    (should (equal (expui-icons--image-props
                    '(:face nil :v-adjust 0.01 :height nil :scale nil))
                   (expui-icons--image-props nil)))
    ;; A float :height is a factor of the default size.
    (should (equal (expui-icons--image-props '(:height 0.8))
                   '(:scale 0.8 :ascent center)))
    (should (equal (expui-icons--image-props '(:height 0.5 :scale 2))
                   '(:scale 1.0 :ascent center)))
    (let ((expui-icons-height 24))
      (should (equal (expui-icons--image-props '(:height 1.0))
                     '(:scale 1.5 :ascent center))))
    (let ((expui-icons-height nil))
      (should (equal (expui-icons--image-props '(:height 1.0))
                     '(:ascent center)))
      (should (equal (expui-icons--image-props '(:height 0.8))
                     '(:scale 0.8 :ascent center))))
    ;; An integer :height stays in pixels.
    (should (equal (expui-icons--image-props '(:height 20 :v-adjust -0.1))
                   '(:height 20 :scale 1 :ascent center)))
    (when (image-type-available-p 'svg)
      ;; Equivalent arguments share one cached image.
      (should (eq (expui-icons-image "python" :height nil :v-adjust 0.0)
                  (expui-icons-image "python"))))))

(ert-deftest expui-icons-test-nerd-icons-calls ()
  (skip-unless (image-type-available-p 'svg))
  (expui-icons-test--with-clean-state
    (cl-letf (((symbol-function 'expui-icons-svg-p) #'always))
      ;; Explicit nil and default-valued arguments, as callers pass them.
      (let ((icon (expui-icons-icon-for-file "a.py" :face nil :v-adjust 0.0
                                             :height nil)))
        (should-not (get-text-property 0 'face icon))
        (should (eq (get-text-property 0 'display icon)
                    (expui-icons-image "python"))))
      (should (eq (get-text-property
                   0 'display (expui-icons-icon-for-dir "/repo/.github"
                                                        :height 1.0))
                  (expui-icons-image "nodes/folderGithub")))
      (let ((default-directory "/repo/.github/"))
        (should (eq (get-text-property 0 'display
                                       (expui-icons-icon-for-dir nil))
                    (expui-icons-image "nodes/folderGithub"))))
      (should (eq (get-text-property 0 'display
                                     (expui-icons-icon-for-extension "PY"))
                  (expui-icons-image "python")))
      (should (eq (get-text-property 0 'display
                                     (expui-icons-icon-for-extension "zzz"))
                  (expui-icons-image "anyType"))))
    (let ((expui-icons-height nil))
      (should (equal (expui-icons--image-props nil) '(:ascent center)))
      (should (equal (expui-icons--image-props '(:height 20))
                     '(:height 20 :scale 1 :ascent center))))))

(ert-deftest expui-icons-test-cache-keys ()
  (skip-unless (image-type-available-p 'svg))
  (expui-icons-test--with-clean-state
    (let ((light (expui-icons-image "python")))
      (should (eq light (expui-icons-image "python")))
      (should (equal (plist-get (cdr light) :file)
                     (expand-file-name "python.svg" expui-icons-directory)))
      ;; Background variant.
      (let* ((expui-icons-background 'dark)
             (dark (expui-icons-image "python")))
        (should-not (eq dark light))
        (should (equal (plist-get (cdr dark) :file)
                       (expand-file-name "python_dark.svg"
                                         expui-icons-directory))))
      ;; Size.
      (should-not (eq light (expui-icons-image "python" :height 32)))
      (let ((expui-icons-height 20))
        (should (equal (plist-get (cdr (expui-icons-image "python")) :scale)
                       1.25)))
      ;; Style.
      (let* ((expui-icons-style 'mono)
             (mono (expui-icons-image "python")))
        (should-not (eq mono light))
        (should (plist-get (cdr mono) :data))
        ;; The background does not change mono images.
        (let ((expui-icons-background 'dark))
          (should (eq mono (expui-icons-image "python"))))
        ;; Substitutes share the replacement's image.
        (should (eq (expui-icons-image "javaScript")
                    (expui-icons-image "xml")))))))

(ert-deftest expui-icons-test-dark-variant-fallback ()
  ;; gitignore has no dark variant upstream.
  (should (equal (expui-icons--file "gitignore" t)
                 (expand-file-name "gitignore.svg" expui-icons-directory)))
  (should (equal (expui-icons--file "no-such-icon")
                 (expand-file-name "anyType.svg" expui-icons-directory))))

(ert-deftest expui-icons-test-custom-set-clears-cache ()
  (let ((expui-icons--cache (make-hash-table :test #'equal))
        (expui-icons-style 'color))
    (puthash 'key 'value expui-icons--cache)
    (customize-set-variable 'expui-icons-style 'color)
    (should (zerop (hash-table-count expui-icons--cache)))))

;;;; Strings

(ert-deftest expui-icons-test-icon-string ()
  (skip-unless (image-type-available-p 'svg))
  (expui-icons-test--with-clean-state
    (cl-letf (((symbol-function 'expui-icons-svg-p) #'always))
      (let ((icon (expui-icons-icon-for-file "a.py" :face 'shadow)))
        (should (equal (substring-no-properties icon) " "))
        (should (eq (get-text-property 0 'face icon) 'shadow))
        (should (eq (get-text-property 0 'display icon)
                    (expui-icons-image "python"))))
      (should (eq (get-text-property
                   0 'display (expui-icons-icon-for-file "x" :directory t))
                  (expui-icons-image "nodes/folder")))
      (should (eq (get-text-property 0 'display (expui-icons-icon-for-dir "x"))
                  (expui-icons-image "nodes/folder")))
      (should (eq (get-text-property
                   0 'display (expui-icons-icon-for-mode 'python-mode))
                  (expui-icons-image "python"))))))

(ert-deftest expui-icons-test-text-fallback ()
  (expui-icons-test--with-clean-state
    (cl-letf (((symbol-function 'expui-icons-svg-p) #'ignore))
      (should (equal (expui-icons-icon "python") ""))
      (let ((expui-icons-text-fallback (lambda (name) (substring name 0 2))))
        (should (equal (expui-icons-icon "python") "py"))
        (should (eq (get-text-property
                     0 'face (expui-icons-icon "python" :face 'bold))
                    'bold))))))

(provide 'expui-icons-test)
;;; expui-icons-test.el ends here
