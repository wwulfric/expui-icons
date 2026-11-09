;;; pack-icons.el --- Pack icons/ into icons.tar.gz -*- lexical-binding: t; -*-

;; SPDX-License-Identifier: Apache-2.0

;;; Commentary:

;; The package reads its icons from icons.tar.gz; icons/ is the same set
;; unpacked, kept in the repository to browse and diff.  This writes the
;; archive from icons/:
;;
;;   emacs -Q --batch -l scripts/pack-icons.el -f expui-icons-pack
;;
;; scripts/update-icons.sh runs it after fetching icons.  The tar is
;; written here rather than by tar(1), so that it is the same on every
;; system: plain ustar members in sorted order, with fixed modes, owners
;; and times (macOS tar would also add extended-attribute entries).
;; gzip -n leaves out the file name and time.

;;; Code:

(defconst expui-icons-pack--root
  (file-name-directory
   (directory-file-name (file-name-directory (or load-file-name
                                                 buffer-file-name))))
  "The package's root directory.")

(defun expui-icons-pack--field (value width)
  "Return the unibyte string VALUE padded with NULs to WIDTH bytes."
  (when (> (length value) width)
    (error "Field %S is longer than %d bytes" value width))
  (concat value (make-string (- width (length value)) 0)))

(defun expui-icons-pack--header (name size)
  "Return the 512-byte ustar header of a regular file NAME of SIZE bytes."
  (let* ((name (encode-coding-string name 'utf-8))
         (header
          (concat (expui-icons-pack--field name 100)
                  "0000644\0" "0000000\0" "0000000\0" ; mode, uid, gid
                  (format "%011o\0" size)
                  "00000000000\0"                     ; mtime
                  "        "                          ; checksum, for now
                  "0"                                 ; regular file
                  (make-string 100 0)                 ; link name
                  "ustar\0" "00"
                  (make-string (+ 32 32 8 8 155 12) 0))))
    (when (> (string-bytes name) 100)
      (error "Name too long for ustar: %s" name))
    (let ((sum (apply #'+ (string-to-list header))))
      (concat (substring header 0 148)
              (format "%06o\0 " sum)
              (substring header 156)))))

(defun expui-icons-pack--tar (directory)
  "Return a ustar archive of the files below DIRECTORY, as a unibyte string."
  (let ((files (sort (directory-files-recursively directory "") #'string<))
        chunks)
    (dolist (file files)
      (let ((data (with-temp-buffer
                    (set-buffer-multibyte nil)
                    (insert-file-contents-literally file)
                    (buffer-string))))
        (push (expui-icons-pack--header (file-relative-name file directory)
                                        (length data))
              chunks)
        (push data chunks)
        (push (make-string (% (- 512 (% (length data) 512)) 512) 0) chunks)))
    ;; Two empty blocks end the archive; pad it to a whole 10240-byte record.
    (push (make-string 1024 0) chunks)
    (let* ((tar (apply #'concat (nreverse chunks)))
           (pad (% (- 10240 (% (length tar) 10240)) 10240)))
      (concat tar (make-string pad 0)))))

(defun expui-icons-pack ()
  "Write icons.tar.gz from icons/ in the package's root directory."
  (let ((tar (expui-icons-pack--tar
              (expand-file-name "icons" expui-icons-pack--root)))
        (archive (expand-file-name "icons.tar.gz" expui-icons-pack--root)))
    (with-temp-buffer
      (set-buffer-multibyte nil)
      (insert tar)
      (unless (zerop (call-process-region (point-min) (point-max) "gzip"
                                          t t nil "-9" "-n" "-c"))
        (error "gzip failed: %s" (buffer-string)))
      (let ((coding-system-for-write 'no-conversion))
        (write-region nil nil archive nil 'silent)))
    (message "Wrote %s (%d bytes, %d bytes unpacked)"
             (file-relative-name archive expui-icons-pack--root)
             (file-attribute-size (file-attributes archive)) (length tar))))

(provide 'pack-icons)
;;; pack-icons.el ends here
