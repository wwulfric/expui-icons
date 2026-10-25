;;; hero.el --- Build the README's hero image -*- lexical-binding: t; -*-

;; SPDX-License-Identifier: Apache-2.0

;;; Commentary:

;; Writes an HTML collage of two project sidebars and a quick-open
;; palette, drawing every icon with expui-icons' own mappings, dark
;; variants and mono conversion.  scripts/hero.sh renders it to
;; docs/hero.png:
;;
;;   emacs -Q --batch -L . -l scripts/hero.el -f expui-icons-hero OUT.html
;;
;; The file lists are taken from real projects: vector (Rust), multica
;; (Go and TypeScript), the seq libraries and an Emacs configuration.

;;; Code:

(require 'expui-icons)
(require 'seq)

(defconst expui-icons-hero--vector
  '((0 "vector" open "~/projects/vector")
    (1 ".cargo" closed) (1 ".github" closed) (1 "benches" closed)
    (1 "lib" closed) (1 "proto" closed)
    (1 "src" open)
    (2 "api" closed) (2 "sinks" closed) (2 "sources" closed)
    (2 "transforms" closed)
    (2 "app.rs") (2 "cli.rs") (2 "lib.rs") (2 "main.rs" nil nil selected)
    (1 "tests" closed)
    (1 ".editorconfig") (1 ".gitignore") (1 ".prettierrc.json")
    (1 "Cargo.lock") (1 "Cargo.toml") (1 "LICENSE") (1 "Makefile")
    (1 "README.md"))
  "Rows of the light sidebar: (DEPTH NAME STATE NOTE SELECTED).
STATE is `open' or `closed' for directories, nil for files.")

(defconst expui-icons-hero--multica
  '((0 "multica" open "~/projects/multica")
    (1 ".github" closed)
    (1 "apps" open)
    (2 "desktop" closed) (2 "mobile" closed)
    (2 "web" open)
    (3 "app" closed) (3 "components" closed)
    (3 "eslint.config.mjs") (3 "next.config.ts") (3 "package.json")
    (3 "tsconfig.json")
    (1 "server" open)
    (2 "cmd" closed) (2 "internal" closed) (2 "migrations" closed)
    (2 "go.mod" nil nil selected) (2 "go.sum") (2 "sqlc.yaml")
    (1 ".env.example") (1 "Dockerfile") (1 "docker-compose.yml")
    (1 "pnpm-lock.yaml") (1 "README.md"))
  "Rows of the dark sidebar, as in `expui-icons-hero--vector'.")

(defconst expui-icons-hero--recent
  '(("init.el" "~/.emacs.d")
    ("ink-theme.el" "~/.emacs.d/lisp/ui")
    ("Seq.java" "seq/src/main/java/com/github/wolray/seq" selected)
    ("seq.py" "seq.py")
    ("seq.rs" "seq/src")
    ("Seq.ts" "seq/src")
    ("001_init.up.sql" "multica/server/migrations")
    ("layout.tsx" "multica/apps/web/app")
    ("main.rs" "vector/src")
    ("Cargo.toml" "vector")
    ("Dockerfile" "multica")
    ("README.md" "vector"))
  "Rows of the palette: (NAME PATH SELECTED).")

(defconst expui-icons-hero--source-icons
  '("xml" "java" "python" "rustFile" "go" "tsx" "kotlin" "c" "cpp")
  "Icons drawn in the accent color in the mono palette.")

(defun expui-icons-hero--svg (name style dark color)
  "Return an <img> of icon NAME in STYLE, DARK variant, mono COLOR."
  (let* ((expui-icons-style style)
         (name (expui-icons--resolve name))
         (svg (with-temp-buffer
                (insert-file-contents
                 (expui-icons--file name (and (eq style 'color) dark)))
                (buffer-string))))
    (when (eq style 'mono)
      ;; An <img> cannot inherit `color', so bake it into the image.
      (setq svg (string-replace "currentColor" color
                                (expui-icons--monochrome svg))))
    (format "<img class=\"i\" src=\"data:image/svg+xml;base64,%s\">"
            (base64-encode-string (encode-coding-string svg 'utf-8) t))))

(defun expui-icons-hero--escape (text)
  "Escape TEXT for HTML."
  (replace-regexp-in-string
   "[&<>]" (lambda (c) (pcase c ("&" "&amp;") ("<" "&lt;") (_ "&gt;")))
   text t t))

(defun expui-icons-hero--tree (rows dark)
  "Return the HTML of sidebar ROWS, using dark variants if DARK."
  (mapconcat
   (pcase-lambda (`(,depth ,name ,state ,note ,selected))
     (concat
      (format "<div class=\"row%s\" style=\"padding-left:%dpx\">"
              (if selected " sel" "") (+ 10 (* depth 18)))
      (pcase state
        ('open (expui-icons-hero--svg "general/chevronDown" 'color dark nil))
        ('closed (expui-icons-hero--svg "general/chevronRight" 'color dark nil))
        (_ "<span class=\"i\"></span>"))
      (expui-icons-hero--svg (expui-icons-name-for-file name state)
                             'color dark nil)
      (format "<span class=\"n%s\">%s</span>" (if (= depth 0) " root" "")
              (expui-icons-hero--escape name))
      (if note (format "<span class=\"note\">%s</span>"
                       (expui-icons-hero--escape note))
        "")
      "</div>"))
   rows "\n"))

(defun expui-icons-hero--palette (rows)
  "Return the HTML of palette ROWS, drawn in the mono style."
  (mapconcat
   (pcase-lambda (`(,name ,path ,selected))
     (let ((icon (expui-icons-name-for-file name)))
       (concat
        (format "<div class=\"prow%s\">" (if selected " sel" ""))
        (expui-icons-hero--svg
         icon 'mono nil
         (if (member (let ((expui-icons-style 'mono))
                       (expui-icons--resolve icon))
                     expui-icons-hero--source-icons)
             "#245FA5" "#747B84"))
        (format "<span class=\"n\">%s</span><span class=\"path\">%s</span>"
                (expui-icons-hero--escape name)
                (expui-icons-hero--escape path))
        "</div>")))
   rows "\n"))

(defconst expui-icons-hero--css "
* { box-sizing: border-box; }
html, body { margin: 0; }
body {
  width: 1600px; height: 1000px; overflow: hidden;
  font: 13.5px/1 -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif;
  -webkit-font-smoothing: antialiased;
  background:
    radial-gradient(900px 560px at 14% 6%, #e3ecfa 0%, transparent 72%),
    radial-gradient(820px 600px at 90% 98%, rgba(36, 95, 165, .10) 0%, transparent 70%),
    linear-gradient(180deg, #f3f4f5 0%, #eceef1 100%);
  position: relative;
}
header { position: absolute; top: 58px; left: 0; right: 0; text-align: center; }
h1 { margin: 0; font-size: 50px; font-weight: 700; letter-spacing: -0.025em; color: #454b53; }
h1 span { color: #245fa5; }
.tag { margin-top: 16px; font-size: 19px; color: #747b84; letter-spacing: 0.005em; }
.tag b { color: #333333; font-weight: 600; }
.win {
  position: absolute; border-radius: 12px; overflow: hidden;
  box-shadow: 0 28px 60px -24px rgba(69, 75, 83, .40), 0 0 0 1px #c7cbd1;
}
.bar { height: 40px; display: flex; align-items: center; padding: 0 14px; gap: 8px; }
.dot { width: 12px; height: 12px; border-radius: 50%; }
.title { margin-left: 14px; font-size: 13px; font-weight: 600; }
.tree { padding: 6px 0 10px; }
.row { height: 26px; display: flex; align-items: center; gap: 6px; white-space: nowrap; margin: 0 6px; border-radius: 6px; }
.i { width: 16px; height: 16px; flex: none; display: inline-block; }
.root { font-weight: 600; }
.note { margin-left: 6px; font-size: 12.5px; }
.light { background: #ffffff; color: #333333; }
.light .bar { background: #eceef1; color: #454b53; }
.light .note { color: #747b84; }
.light .sel { background: #ecedef; }
.dark { background: #2b2d30; color: #dfe1e5; }
.dark .bar { background: #1e1f22; color: #c9ccd2; }
.dark .note { color: #6f737a; }
.dark .sel { background: #43454a; }
.palette {
  position: absolute; left: 452px; top: 250px; width: 696px;
  background: #ffffff; border-radius: 14px; overflow: hidden; color: #333333;
  box-shadow: 0 40px 90px -30px rgba(69, 75, 83, .55), 0 0 0 1px #c7cbd1;
}
.search { height: 56px; display: flex; align-items: center; gap: 12px; padding: 0 20px;
  border-bottom: 1px solid #e4e7eb; font-size: 17px; }
.search .q { color: #a0a6ad; }
.search .caret { width: 2px; height: 20px; background: #245fa5; margin-right: -10px; }
.search .hint { margin-left: auto; font-size: 12px; color: #747b84; }
.kbd { display: inline-block; padding: 3px 6px; border-radius: 5px; background: #f3f4f5;
  border: 1px solid #e4e7eb; font-size: 11.5px; color: #747b84; margin-left: 4px; }
.section { padding: 14px 22px 6px; font-size: 11.5px; font-weight: 600; letter-spacing: .06em;
  text-transform: uppercase; color: #747b84; }
.list { padding: 0 8px 10px; }
.prow { height: 34px; display: flex; align-items: center; gap: 12px; padding: 0 14px;
  border-radius: 8px; font-size: 14.5px; }
.prow .path { margin-left: auto; font-size: 12.5px; color: #747b84; }
.prow.sel { background: #e3ecfa; }
.prow.sel .path { color: #66717e; }
.foot { display: flex; gap: 22px; padding: 12px 22px; border-top: 1px solid #e4e7eb;
  background: #f3f4f5; font-size: 12px; color: #747b84; }
")

(defun expui-icons-hero--window (class left top width title rows dark)
  "Return a sidebar window of CLASS at LEFT, TOP and WIDTH.
TITLE names it; ROWS are drawn with dark variants if DARK."
  (format "<div class=\"win %s\" style=\"left:%dpx;top:%dpx;width:%dpx\">
<div class=\"bar\"><span class=\"dot\" style=\"background:#ff5f57\"></span><span class=\"dot\" style=\"background:#febc2e\"></span><span class=\"dot\" style=\"background:#28c840\"></span><span class=\"title\">%s</span></div>
<div class=\"tree\">%s</div></div>"
          class left top width title (expui-icons-hero--tree rows dark)))

(defun expui-icons-hero-html ()
  "Return the hero image as an HTML page."
  (let ((expui-icons-height 16))
    (concat
     "<!doctype html><html><head><meta charset=\"utf-8\"><style>"
     expui-icons-hero--css
     "</style></head><body>
<header><h1>expui<span>-</span>icons</h1>
<div class=\"tag\">IntelliJ New UI icons for Emacs · <b>color</b> &amp; <b>mono</b> · <b>light</b> &amp; <b>dark</b></div></header>\n"
     (expui-icons-hero--window "light" 48 206 380 "Project — vector"
                               expui-icons-hero--vector nil)
     (expui-icons-hero--window "dark" 1172 206 380 "Project — multica"
                               expui-icons-hero--multica t)
     "<div class=\"palette\"><div class=\"search\">"
     (expui-icons-hero--svg "general/search" 'mono nil "#747B84")
     "<span class=\"caret\"></span><span class=\"q\">Search files</span>"
     "<span class=\"hint\">"
     "<span class=\"kbd\">⌘</span><span class=\"kbd\">P</span></span></div>"
     "<div class=\"section\">Recent files</div><div class=\"list\">"
     (expui-icons-hero--palette expui-icons-hero--recent)
     "</div><div class=\"foot\"><span><span class=\"kbd\">↵</span> open</span>"
     "<span><span class=\"kbd\">⌘↵</span> open in split</span>"
     "<span><span class=\"kbd\">esc</span> close</span></div></div>"
     "</body></html>\n")))

(defun expui-icons-hero ()
  "Write the hero image's HTML to the file named on the command line."
  (let ((file (pop command-line-args-left)))
    (with-temp-file file
      (insert (expui-icons-hero-html)))
    (message "Wrote %s" file)))

(provide 'hero)
;;; hero.el ends here
