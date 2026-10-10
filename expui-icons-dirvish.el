;;; expui-icons-dirvish.el --- Dirvish file icons -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Lufei Wang

;; Author: Lufei Wang <wwulfric@gmail.com>
;; URL: https://github.com/wwulfric/expui-icons
;; SPDX-License-Identifier: Apache-2.0

;;; Commentary:

;; Defines the Dirvish attribute `expui-icons'.  This file requires
;; Dirvish; load it only in configurations that use Dirvish:
;;
;;   (with-eval-after-load 'dirvish
;;     (require 'expui-icons-dirvish)
;;     (push 'expui-icons dirvish-attributes))
;;
;; `expui-icons-dirvish-face-function' chooses each icon's face, which
;; sets its color in the `mono' style.

;;; Code:

(require 'expui-icons)
(require 'dirvish)

(defface expui-icons-dirvish-icon '((t))
  "Face of file icons in Dirvish."
  :group 'expui-icons)

(defcustom expui-icons-dirvish-face-function #'expui-icons-dirvish-default-face
  "Function returning the face of an icon.
It is called with the icon name and whether the file is a directory."
  :type 'function
  :group 'expui-icons)

(defcustom expui-icons-dirvish-gap 6
  "Pixels between an icon and the file name."
  :type 'natnum
  :group 'expui-icons)

(defun expui-icons-dirvish-default-face (_name _directory)
  "Return `expui-icons-dirvish-icon' for every icon."
  'expui-icons-dirvish-icon)

(dirvish-define-attribute expui-icons
  "File icons from IntelliJ's New UI."
  :when (expui-icons-svg-p)
  :width 3
  (let* ((directory (eq (car f-type) 'dir))
         (name (expui-icons-name-for-file f-str directory))
         (face (funcall expui-icons-dirvish-face-function name directory))
         (ov (make-overlay (1- f-beg) f-beg)))
    ;; On the current line the highlight supplies only the background.
    (when hl-face
      (setq face (delq nil (list face hl-face))))
    (overlay-put ov 'after-string
                 (concat (expui-icons-icon name :face face)
                         (propertize " " 'display
                                     `(space :width (,expui-icons-dirvish-gap))
                                     'face hl-face)))
    `(ov . ,ov)))

(provide 'expui-icons-dirvish)
;;; expui-icons-dirvish.el ends here
