;;; init-basic.el --- Basic configurations

;;; Commentary:
;;

;;; Code:

(defconst boem-version-string
  (mapconcat 'identity
             (mapcar
              #'(lambda(x) (number-to-string x))
              (version-to-list emacs-version))
             ".")
  "Emacs version as string.")

(defconst boem-user-package-directory
  (expand-file-name (format "packages/%s" boem-version-string) boem-init-root))
(defconst boem-user-data-directory
  (expand-file-name "data" boem-init-root))
(defconst boem-user-themes-directory
  (expand-file-name "themes" boem-init-root))
(defconst boem-user-org-directory
  (expand-file-name "~/org-files"))

(make-directory boem-user-package-directory t)
(make-directory boem-user-data-directory t)
(make-directory boem-user-themes-directory t)
(make-directory boem-user-org-directory t)

(defun boem-install-package-if-needed (package &optional min-version no-refresh)
  "Install required PACKAGE, optionally requiring MIN-VERSION.
If package is not found in the available package list or NO-REFRESH
is true refresh is skipped"
  (if (package-installed-p package)
      t
    (if (or (assoc package package-archive-contents) no-refresh)
        (package-install package)
      (progn
        (package-refresh-contents)
        (boem-install-package-if-needed package min-version t)))))

(defun boem-add-subdirs-to-load-path (root-dir)
  "Add all first lever sub directories of ROOT-DIR to load path."
  (dolist (entry (directory-files root-dir t "\\w+"))
    (when (file-directory-p entry)
      (if (string-match "theme" entry)
          (add-to-list 'custom-theme-load-path entry)
        (add-to-list 'load-path entry)))))

(boem-add-subdirs-to-load-path boem-user-package-directory)

;; My theme
(add-to-list 'custom-theme-load-path boem-user-themes-directory)

(defun boem-change-theme (theme)
  "Activate THEME from the list of themes I use."
  (interactive "sTheme name: ")
  (if (string-equal theme "my-rails-casts")
      (load-theme (intern theme) t))
  (if (string-equal theme "tangotango")
      (progn
        (load-theme (intern theme) t)
        (custom-set-faces '(highlight ((t :background "gray9")))))))

;;;; rename-modeline
(defmacro boem-rename-modeline (package-name mode new-name)
  `(eval-after-load ,package-name
     '(defadvice ,mode (after boem-rename-modeline activate)
        (setq mode-name ,new-name))))

;;;; Modes and mode groupings
(defmacro boem-hook-into-modes (func modes)
  "Add hook `FUNC' to multiple `MODES'."
  `(dolist (mode-hook ,modes)
     (add-hook mode-hook ,func)))

(defvar boem-prog-mode-hooks
  '(prog-mode-hook
    emacs-lisp-mode-hook
    pyhon-mode-hook
    coffee-mode-hook
    js-mode-hook
    js2-mode-hook
    ruby-mode-hook
    haskell-mode-hook
    clojure-mode-hook
    go-mode-hook))

(defun boem-current-buffer-remote-p ()
  (--any? (and it (file-remote-p it))
          (list
           (buffer-file-name)
           list-buffers-directory
           default-directory))
  ;; (and (fboundp 'tramp-tramp-file-p) (-any? 'tramp-tramp-file-p
  ;; (list
  ;; (buffer-file-name)
  ;; list-buffers-directory
  ;; default-directory)))
  )

(defun boem-insert-line-above ()
  "Insert and indent line above current point."
  (interactive)
  (move-beginning-of-line nil)
  (newline)
  (forward-line -1)
  (indent-according-to-mode))

(defun boem-insert-line ()
  "Insert and indent line above current point."
  (interactive)
  (move-end-of-line nil)
  (newline)
  (indent-according-to-mode))

(defun boem-open-term ()
  "Open 'ansi-term' with default shell."
  (interactive)
  (ansi-term (getenv "SHELL")))

(defun boem-duplicate-line-or-region ()
  (interactive)
  (let ((string "")  (end nil))
    (if (use-region-p)
        (progn
          (setq end (region-end))
          (setq string (buffer-substring-no-properties (region-beginning) end))
          (goto-char end))
      (progn
        (setq end (line-end-position)
              string (buffer-substring-no-properties (line-beginning-position) end))
        (goto-char end)
        (newline)))
    (insert string)))

;; Add Imenu index to the menu bar in any mode that supports Imenu.
(defun boem-try-to-add-imenu ()
  (condition-case nil (imenu-add-to-menubar "Methods") (error nil)))
(add-hook 'font-lock-mode-hook 'boem-try-to-add-imenu)

(provide 'init-basic)

;;; init-basic.el ends here
