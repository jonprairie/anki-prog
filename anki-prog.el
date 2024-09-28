;;; anki-prog.el --- Answer programming questions in Anki  -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2024 Jonathan Prairie
;;
;; Author: Jonathan Prairie <jon.a.prairie@gmail.com>
;; Maintainer: Jonathan Prairie <jon.a.prairie@gmail.com>
;; Created: September 28, 2024
;; Modified: September 28, 2024
;; Version: 0.0.1
;; Package-Requires: ((emacs "26.0"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;; Answer programming questions in Anki
;;
;;
;;; Code:


(require 'anki-editor)
(require 'dash)
(require 's)


(defvar anki-prog-languages
  '("javascript" "C" "emacs-lisp" "common-lisp" "python" "text" "bash"))

(defvar anki-prog-language-headers
  '(("emacs-lisp" . ":lexical t")))

(defun anki-prog-begin-question (question language)
  (interactive)
  (unless (and language (-contains? anki-prog-languages language))
    (setf language (completing-read "Choose language:" anki-prog-languages nil t)))
  (let ((anki-prog-buffer-name "*anki programming answer*")
        (headers (alist-get language anki-prog-language-headers nil nil #'string=)))
    (with-current-buffer (get-buffer-create anki-prog-buffer-name)
      (erase-buffer)
      (org-mode)
      (insert (format "#+BEGIN_SRC %s %s\n#+END_SRC"
                      language
                      (if headers headers "")))
      (switch-to-buffer anki-prog-buffer-name t t)
      (org-edit-special)
      (insert question "\n\n")
      (unless (string= language "text")
        (comment-region 0 (point))))))

(defun anki-prog-get-first-field (fields)
  (message "fields: %s" fields)
  (cl-loop for field in fields
           for order = (alist-get 'order field) do
           (if (= order 0)
               (cl-return field))))

(defun anki-prog-do-current-card ()
  (interactive)
  (if-let (card (cdr (anki-editor-api-call-result 'guiCurrentCard)))
      (let* ((fields (alist-get 'fields card))
             (question (anki-prog-get-first-field fields))
             (question (anki-prog-strip-html (alist-get 'value question)))
             (lang (alist-get 'Language fields))
             (lang (when lang (anki-prog-strip-html (alist-get 'value lang)))))
        (anki-prog-begin-question question lang))
    (message "No card being reviewed.")))

(defun anki-prog-strip-html (s)
  "Remove HTML tags from string S."
  (let* ((s (s-replace-regexp "<[^<]*>" "" s))
         (s (s-replace "&copy;" "(c)" s))
         (s (s-replace "&rsquo;" "'" s))
         (s (s-replace "&amp;" "&" s))
         (s (s-replace "&lt;" "<" s))
         (s (s-replace "&gt;" ">" s)))
    (s-trim s)))


(provide 'anki-prog)
;;; anki-prog.el ends here
