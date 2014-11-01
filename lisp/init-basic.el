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

(defun boem-kill-user-buffers ()
  "Kills all opened buffers except *scratch* and *Messages*"
  (interactive)
  (let ((not-to-kill-buffer-list '("*scratch*" "*Messages*")))
    (dolist (buff (buffer-list))
      (if (and
           (not (s-starts-with? " " (buffer-name buff)))
           (not (member (buffer-name buff) not-to-kill-buffer-list)))
          (kill-buffer (buffer-name buff))))))

(defun boem-comment-uncomment ()
  (interactive)
  (save-excursion
    (if (not (region-active-p))
        (progn
          (beginning-of-line)
          (push-mark)
          (end-of-line)))
    (call-interactively 'comment-or-uncomment-region)))

;; Add Imenu index to the menu bar in any mode that supports Imenu.
(defun boem-try-to-add-imenu ()
  (condition-case nil (imenu-add-to-menubar "Methods") (error nil)))
(add-hook 'font-lock-mode-hook 'boem-try-to-add-imenu)

(defun boem-switch-to-previous-buffer ()
  "Switch to previously open buffer.
Repeated invocations toggle between the two most recently open buffers.
Code from: http://emacsredux.com/blog/2013/04/28/switch-to-previous-buffer/"
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) 1)))

;; Taken from http://p.writequit.org/org/settings.html
;; For OS X
;; brew install ctags
;; wget -c http://tamacom.com/global/global-6.3.1.tar.gz
;; tar zxvf global-6.3.1.tar.gz
;; cd global-6.3.1
;; ./configure --prefix=/usr/local --with-exuberant-ctags=/usr/local/bin/ctags
;; make install
;;
;; I also add this to my shell configuration:
;;
;; export GTAGSCONF=/usr/local/share/gtags/gtags.conf
;; export GTAGSLABEL=ctags
(defun boem-setup-ggtags ()
  (interactive)
  (ggtags-mode 1)
  ;; turn on helm-mode for completion
  ;; (helm-mode 1)
  ;; turn on eldoc with ggtags
  (setq-local eldoc-documentation-function #'ggtags-eldoc-function)
  ;; add ggtags to the hippie completion
  (setq-local hippie-expand-try-functions-list
              (cons 'ggtags-try-complete-tag
                    hippie-expand-try-functions-list))
  ;; use helm for completion
  (setq ggtags-completing-read-function nil))

(provide 'init-basic)

;;; init-basic.el ends here
