;;; package --- initialisation
;;; Commentary:
;;; init routine for Emacs

;;; Code:
(require 'cl-lib)
(require 'projectile)


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(desktop-save-mode t)
 '(fill-column 80)
 '(initial-scratch-message nil)
 '(scroll-bar-mode nil)
 '(visible-bell t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


;; Set default directory
(when (eq system-type 'windows-nt)
  (setq default-directory "C:/code/"))


;; Enable yasnippet
(require 'yasnippet)
(yas-global-mode 1)


;; Enable line numbers in files (but not shells etc.)
(add-hook 'find-file-hook (lambda () (linum-mode 1)))


;; Tail (refresh) log files automatically
(add-to-list 'auto-mode-alist '("\\.log\\'" . auto-revert-mode))


(defun comment-or-uncomment-region-or-line ()
  "Comment or uncomment the region or the current line if region not active."
  (interactive)
  (let (beg end)
    (if (region-active-p)
        (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (comment-or-uncomment-region beg end)
    (forward-line)))

;; Rebind comment-dwim to comment-or-uncomment-region-or-line
(global-set-key "\M-;" 'comment-or-uncomment-region-or-line)


;; Enable convenient buffer switching
(defun switch-to-previous-buffer ()
  "Switch to most recent buffer.
Repeated calls toggle back and forth between the most recent two buffers."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) 1)))

;; Set key binding for buffer switching
(global-set-key (kbd "C-`") 'switch-to-previous-buffer)


(defun save-macro (name)
  "Save a macro.
Take a NAME as argument and save the last defined macro under
NAME at the end of your .emacs"
     (interactive "SName of the macro :")  ; ask for the name of the macro
     (kmacro-name-last-macro name)         ; use this name for the macro
     (save-excursion                       ; return to this buffer later
       (find-file user-init-file)            ; open ~/.emacs or other init file
       (goto-char (point-max))               ; go to the end of the .emacs
       (newline)                             ; insert a newline
       (insert-kbd-macro name)               ; copy the macro
       (newline)))                           ; insert a newline


(defun write-input-ring (filename)
  "Write shell input to FILENAME then visit FILENAME."
  (interactive "F")
  (let ((comint-input-ring-file-name filename))
    (comint-write-input-ring))

  (if (file-readable-p filename)
      ;; If the input ring was saved to a file, visit that file
      (find-file filename)
    ;; Else report that no input was saved
    (message "This buffer has no shell history.")))


(defun clean-text ()
  "Yank text from the killring, replace newlines with spaces, and copy to killring."
  (interactive)
  (with-temp-buffer
    (yank) ; Yank (paste) contents of clipboard
    (goto-char (point-min))
    (while (search-forward "(\n)" nil t)
      (replace-match " ")
      (clipboard-kill-ring-save (point-min) (point-max)))))


(defun format-sgml-region (begin end)
  "Format SGML markup in region between BEGIN and END.
The function inserts linebreaks to separate tags that have nothing but
whitespace between them.  It then indents the markup by using nxml's
indentation rules."
  (interactive "r")
  (save-excursion
    (nxml-mode)
    (goto-char begin)
    ;; split <foo><foo> or </foo><foo>, but not <foo></foo>
    (while (search-forward-regexp ">[ \t]*<[^/]" end t)
      (backward-char 2)
      (insert "\n")
      (cl-incf end))
    ;; split <foo/></foo> and </foo></foo>
    (goto-char begin)
    (while (search-forward-regexp "<.*?/.*?>[ \t]*<" end t)
      (backward-char)
      (insert "\n")
      (cl-incf end))
    (indent-region begin end nil)
    (normal-mode))
  (message "SGML indented"))


;; Set IPython interpreter
(defvar python-shell-interpreter "ipython")
(defvar python-shell-interpreter-args "-i")
;; Require Python after the interpreter variables are set so we don't
;; have to use setq on a free global variable
(require 'python)


(defun python-test-project ()
  "Run default Python unit test command."
  (interactive)
  (when (eq major-mode 'python-mode)
    (setq projectile-project-test-cmd "python -m unittest")
    (setq compilation-read-command nil)
    (projectile-test-project nil)))


(defun python-toggle-test-on-save ()
  "Toggle whether projectile-test-project is run on saving a Python file."
  (interactive)
  ;; Create a 'state' property for the function object to save state
  (if (get 'python-toggle-test-on-save 'state)
      (progn
        ;; Turn off saving if python-test-on-save is true
        (put 'python-toggle-test-on-save 'state nil)
        (remove-hook 'after-save-hook 'python-test-project)
        (message "Test on save unset."))
    ;; Turn on saving if python-test-on-save is false
    (put 'python-toggle-test-on-save 'state t)
    (add-hook 'after-save-hook 'python-test-project)
    (message "Test on save set.")))

(python-toggle-test-on-save)


(defun python-send-buffer-args (args)
  "Run Python script with ARGS as arguments."
  (interactive "sPython arguments: ")
  (let ((source-buffer (current-buffer)))
    (with-temp-buffer
      (insert "import sys; sys.argv = '''" args "'''.split()\n")
      (insert-buffer-substring source-buffer)
      (python-shell-send-buffer))))


(defun python-shell-repeat ()
  "Repeat the last command in the Python shell."
  (switch-to-buffer-other-window "*Python*")
  (goto-char (point-max))
  ;; Go one input item backwards
  (comint-previous-input 1)
  (insert "\n"))


(provide 'custom)
;;; custom.el ends here
