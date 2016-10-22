;;; nnnotmuch.el --- Notmuch search engine back-end for Gnus

;; Author: Teemu Likonen <tlikonen@iki.fi>
;; Created: 2016-10-21
;; URL: https://github.com/tlikonen/nnnotmuch
;; Keywords: Gnus Notmuch back-end server

;; Copyright (C) 2016 Teemu Likonen <tlikonen@iki.fi>
;;
;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; The license text: <http://www.gnu.org/licenses/gpl-3.0.html>

;;; Code:

(require 'cl-lib)
(require 'nnheader)
(require 'nnoo)
(require 'nnml)

(nnoo-declare nnnotmuch nnml)
(nnoo-define-basics nnnotmuch)

(defvar nnnotmuch-program "notmuch")
(defvar nnnotmuch--buffer-name " *notmuch*")
(defvar nnnotmuch-current-server nil)
(defvar nnnotmuch-current-group nil)
(defvar nnnotmuch-groups nil)

(defun nnnotmuch--error (&rest format-args)
  (apply #'nnheader-report 'nnnotmuch format-args)
  nil)

(defun nnnotmuch--get-groups (server)
  (mapcar #'car (cdr (cl-assoc server nnnotmuch-groups
                               :test #'equal))))

(defun nnnotmuch--get-terms (server group)
  (cdr (cl-assoc group (cdr (cl-assoc server nnnotmuch-groups
                                      :test #'equal))
                 :test #'equal)))

(defun nnnotmuch--call-notmuch (&rest args)
  (apply #'call-process nnnotmuch-program nil t nil args))

(defun nnnotmuch--get-message-ids (terms)
  (with-temp-buffer
    (let ((status (apply #'nnnotmuch--call-notmuch
                         "search" "--format=sexp" "--output=messages"
                         "--sort=oldest-first" "--" terms)))
      (if (not (eql 0 status))
          (nnnotmuch--error "Couldn't retrieve message ids")
        (goto-char (point-min))
        (read (current-buffer))))))

(defun nnnotmuch--get-header (message-id)
  (with-current-buffer (get-buffer-create nnnotmuch--buffer-name)
    (erase-buffer)
    (let ((status (nnnotmuch--call-notmuch
                   "show" "--entire-thread=false" "--format=mbox" "--"
                   (format "id:%s" message-id))))
      (if (not (eql 0 status))
          (nnnotmuch--error "Couldn't retrieve header for <%s>" message-id)
        (goto-char (point-min))
        (nnheader-parse-head t)))))

(defun nnnotmuch--insert-nov-line (number header)
  (let ((extra (cl-remove-if-not (lambda (header)
                                   (member header nnmail-extra-headers))
                                 (mail-header-extra header)
                                 :key #'car)))
    (insert (format "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s%s\n"
                    number
                    (mail-header-subject header)
                    (mail-header-from header)
                    (mail-header-date header)
                    (mail-header-id header)
                    (mail-header-references header)
                    (mail-header-chars header)
                    (mail-header-lines header)
                    (mail-header-xref header)
                    (let ((out ""))
                      (dolist (e extra out)
                        (setq out (format "%s\t%s: %s"
                                          out (car e) (cdr e)))))))))

(defun nnnotmuch--message-count (terms)
  (with-temp-buffer
    (let ((status (apply #'nnnotmuch--call-notmuch "count" "--output=messages"
                         "--" terms)))
      (if (not (eql 0 status))
          (nnnotmuch--error "Couldn't retrieve message count")
        (goto-char (point-min))
        (string-to-number
         (buffer-substring-no-properties (point) (line-end-position)))))))

(deffoo nnnotmuch-retrieve-headers (articles &optional group server fetch-old)
  (setq group (or group nnnotmuch-current-group))
  (if server
      (setq nnnotmuch-current-server server)
    (setq server nnnotmuch-current-server))

  (let ((terms (nnnotmuch--get-terms server group)))
    (if (not terms)
        (nnnotmuch--error "Invalid group data (nnnotmuch-groups")
      (let ((message-ids (nnnotmuch--get-message-ids terms))
            (number 1))
        (if (not message-ids)
            (nnnotmuch--error "No messages")
          (with-current-buffer nntp-server-buffer
            (erase-buffer)
            (dolist (id message-ids)
              (nnnotmuch--insert-nov-line
               number (nnnotmuch--get-header id))
              (setq number (1+ number)))
            'nov))))))

(deffoo nnnotmuch-open-server (server &optional definitions)
  (setq nnnotmuch-current-server server)
  (nnoo-change-server 'nnnotmuch server definitions)
  (let ((groups (cdr (cl-assoc server nnnotmuch-groups :test #'equal))))
    (if (not groups)
        (nnnotmuch--error "No group definitions for this server")
      t)))

(deffoo nnnotmuch-close-server (&optional server)
  (if server
      (setq nnnotmuch-current-server server)
    (setq server nnnotmuch-current-server))
  (nnoo-close-server 'nnnotmuch))

(deffoo nnnotmuch-request-close ()
  (setq nnnotmuch-current-server nil)
  (setq nnnotmuch-current-group nil)
  t)

(deffoo nnnotmuch-server-opened (&optional server)
  (if server
      (setq nnnotmuch-current-server server)
    (setq server nnnotmuch-current-server))
  (nnnotmuch--get-groups server))

;; (deffoo nnnotmuch-status-message (&optional server)
;;   nnnotmuch--last-error)

(deffoo nnnotmuch-request-article (article &optional group server to-buffer)
  (setq group (or group nnnotmuch-current-group))
  (if server
      (setq nnnotmuch-current-server server)
    (setq server nnnotmuch-current-server))


  (when (numberp article)
    (let ((terms (nnnotmuch--get-terms server group)))
      (if (not terms)
          (nnnotmuch--error "Invalid group data (nnnotmuch-groups")
        (setq article (nth (1- article)
                           (nnnotmuch--get-message-ids terms))))))

  (if (not (stringp article))
      (nnnotmuch--error "Invalid article %s" article)
    (with-current-buffer (or to-buffer nntp-server-buffer)
      (erase-buffer)
      (let ((status (nnnotmuch--call-notmuch
                     "show" "--entire-thread=false" "--format=mbox"
                     "--part=0" "--body=true" "--"
                     (format "id:%s" article))))
        (if (not (eql 0 status))
            (nnnotmuch--error "Error retrieving article %s" article)
          t)))))

(deffoo nnnotmuch-request-group (group &optional server fast info)
  (if server
      (setq nnnotmuch-current-server server)
    (setq server nnnotmuch-current-server))
  (setq nnnotmuch-current-group group)
  (if fast
      t
    (let ((count (nnnotmuch--message-count
                  (nnnotmuch--get-terms server group))))
      (with-current-buffer nntp-server-buffer
        (erase-buffer)
        (if (not (integerp count))
            (nnnotmuch--error "Couldn't get the number of articles for %s" group)
          (insert (format "211 %s 1 %s %s\n" count count group))
          t)))))

(deffoo nnnotmuch-close-group (group &optional server) t)

(deffoo nnnotmuch-request-list (&optional server)
  (if server
      (setq nnnotmuch-current-server server)
    (setq server nnnotmuch-current-server))
  (let ((groups (nnnotmuch--get-groups server)))
    (if (not groups)
        (nnnotmuch--error "Couldn't retrieve groups for server %s" server)
      (with-current-buffer nntp-server-buffer
        (erase-buffer)
        (dolist (group groups)
          (insert (format "%s %s 1 n\n" group
                          (or (nnnotmuch--message-count
                               (nnnotmuch--get-terms server group))
                              0))))
        t))))

;; (deffoo nnnotmuch-request-post (&optional server) t)
(nnoo-map-functions nnnotmuch
  (nnml-request-post 0))

(gnus-declare-backend "nnnotmuch" 'post-mail 'address)

(provide 'nnnotmuch)
