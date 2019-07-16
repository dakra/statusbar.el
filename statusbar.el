;;; statusbar.el --- Minor mode for working with statusbar projects  -*- lexical-binding: t -*-

;; Copyright (c) 2018 Daniel Kraus <daniel@kraus.my>

;; Author: Daniel Kraus <daniel@kraus.my>
;; URL: https://github.com/dakra/statusbar.el
;; Keywords: statusbar tooltip childframe exwm
;; Version: 0.1
;; Package-Requires: ((emacs "26") (posframe "0.5"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Display statusbar in childfram in the bottom right over
;; parts of the minibuffer.

;;; Code:

(require 'subr-x)
(require 'posframe)


;;; Customization

(defgroup statusbar nil
  "Display a statusbar over the minibuffer"
  :prefix "statusbar-"
  :group 'convenience)

(defcustom statusbar-note nil
  "A note prepended to the statusbar before the variables."
  :type 'string)

(defcustom statusbar-variables nil
  "Variables that will be shown in the statusbar.
Similar to `statusbar-modeline-variables', they will be watched for changes
and the statusbar updated but they will not be removed from `global-mode-string'."
  :type 'list)

(defcustom statusbar-modeline-variables '(org-mode-line-string display-time-string battery-mode-line-string)
  "Variables to remove from the mode-line and display in the statusbar instead.
All variables listed here will be removed from `global-mode-string' and
displayed in the statusbar instead."
  :type 'list)

(defcustom statusbar-x-offset 10
  "Offset to the right side of the statusbar.
If you use exwm systray, Offset counts from the last systray icon."
  :type 'integer)

(defcustom statusbar-status-seperator " "
  "Separator between statusbar entries."
  :type 'string)

(defcustom statusbar-left-fringe 0
  "Left fringe width of the statusbar."
  :type 'integer)

(defcustom statusbar-right-fringe 0
  "Right fringe width of the statusbar."
  :type 'integer)


;;; Variables

(defvar statusbar--buffer-name " *statusbar-buffer*"
  "Name of the statusbar buffer.")


;;; Private helper functions

(defun statusbar--get-buffer ()
  "Return statusbar buffer."
  (get-buffer-create statusbar--buffer-name))

(defun statusbar--line-length (buf)
  "Return current line length of the statusbar text.
BUF is the statusbar buffer."
  (with-current-buffer buf
    (point-max)))

(defun statusbar--position-handler (info)
  "Posframe position handler.
INFO is the childframe plist from `posframe'.
Position the statusbar in the bottom right over the minibuffer."
  (let* ((font-width (plist-get info :font-width))
         (buf (plist-get info :posframe-buffer))
         (buf-width (* font-width (statusbar--line-length buf)))
         (parent-frame (plist-get info :parent-frame))
         (parent-frame-width (frame-pixel-width parent-frame))
         (exwm-systemtray-offset
          (if-let* ((tray-list exwm-systemtray--list)
                    (icon-size (+ exwm-systemtray--icon-min-size exwm-systemtray-icon-gap))
                    (tray-width (* (length exwm-systemtray--list) icon-size)))
              tray-width
            0))
         (x-offset (plist-get info :x-pixel-offset))
         (x-pos (- parent-frame-width buf-width x-offset exwm-systemtray-offset))
         (y-pos -1))
    (cons x-pos y-pos)))

(defun statusbar--display (&rest txts)
  "Display TXTS in the statusbar."
  (let ((buf (statusbar--get-buffer))
        (posframe-mouse-banish nil)
        (inhibit-read-only t)
        (buffer-read-only nil))
    (posframe-show buf
                   :string (mapconcat 'identity txts statusbar-status-seperator)
                   :x-pixel-offset statusbar-x-offset
                   :poshandler 'statusbar--position-handler
                   :left-fringe statusbar-left-fringe
                   :right-fringe statusbar-right-fringe)))

(defun statusbar--delete ()
  "Delete statusbar frame and buffer.
This will only delete the frame and *NOT* remove the variable watchers."
  (posframe-delete-frame (statusbar--get-buffer))
  (kill-buffer (statusbar--get-buffer)))

(defun statusbar--transfer-modeline-vars (&rest _)
  "Watch variables from the modeline and put them in the statusbar."
  (dolist (var statusbar-modeline-variables)
    (when (memq var global-mode-string)
      (add-variable-watcher var #'statusbar-refresh)
      (setq global-mode-string (delete var global-mode-string)))))

;;; Public functions

(defun statusbar-refresh (&rest _)
  "Refresh statusbar with new variable values."
  (apply #'statusbar--display statusbar-note
         (mapcar #'symbol-value (append statusbar-variables statusbar-modeline-variables))))

(defun statusbar-add-note (note)
  "Add a NOTE as first element in the statusbar."
  (interactive "sNote to show in the statusbar: ")
  (setq statusbar-note note)
  (statusbar-refresh))

(defun statusbar-remove-note ()
  "Remove note text from the statusbar."
  (interactive)
  (setq statusbar-note nil)
  (statusbar-refresh))


;;; statusbar-mode

;;;###autoload
(define-minor-mode statusbar-mode
  "Global minor mode to toggle child frame statusbar."
  :global t
  (if statusbar-mode
      (progn
        (add-to-list 'focus-in-hook 'statusbar-refresh)
        (statusbar--transfer-modeline-vars)
        (statusbar-refresh)
        ;; Watch mode-line and when a mode that is specified in `statusbar-modeline-variables'
        ;; Is activated, remove it from the mode-line and show it in the statusbar instead.
        (add-variable-watcher 'global-mode-string #'statusbar--transfer-modeline-vars))

    (setq focus-in-hook (delete 'statusbar-refresh focus-in-hook))
    (dolist (var statusbar-modeline-variables)
      (remove-variable-watcher var #'statusbar-refresh)
      (add-to-list 'global-mode-string var t))
    (statusbar--delete))
  (force-mode-line-update))

(provide 'statusbar)
;;; statusbar.el ends here
