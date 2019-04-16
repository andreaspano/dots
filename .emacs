;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(require 'package)

(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  (when no-ssl
    (warn "\
Your version of Emacs does not support SSL connections,
which is unsafe because it allows man-in-the-middle attacks.
There are two things you can do about this warning:
1. Install an Emacs version that does support SSL and be safe.
2. Remove this warning from your init file so you won't see it again."))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives (cons "gnu" (concat proto "://elpa.gnu.org/packages/")))))
(package-initialize)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(cua-mode t nil (cua-base))
 '(package-selected-packages (quote (markdown-mode use-package ess auctex))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


;; markdown mode
(use-package markdown-mode
  :ensure t
  :commands (markdown-mode gfm-mode)
  :mode (("README\\.md\\'" . gfm-mode))
  :init (setq markdown-command "/usr/local/bin/multimarkdown"))


;; emacs speaks statistics
(use-package ess
  :ensure t
  :init (require 'ess-site))

;; Tell emacs where is your personal elisp lib dir
(add-to-list 'load-path "~/.emacs.d/lisp/")


;; emacs speak shell
;; (require 'essh)                                                   
;;(defun essh-sh-hook ()                                             
;;   (define-key sh-mode-map "\C-c\C-r" 'pipe-region-to-shell)        
;;   (define-key sh-mode-map "\C-c\C-b" 'pipe-buffer-to-shell)        
;;   (define-key sh-mode-map "\C-c\C-j" 'pipe-line-to-shell)          
;;   (define-key sh-mode-map "\C-c\C-n" 'pipe-line-to-shell-and-step) 
;;   (define-key sh-mode-map "\C-c\C-f" 'pipe-function-to-shell)      
;;   (define-key sh-mode-map "\C-c\C-d" 'shell-cd-current-directory)) 
;;(add-hook 'sh-mode-hook 'essh-sh-hook)

;; remove toolbar
(tool-bar-mode -1)

 ;;remove menu
(menu-bar-mode -1)

;; remove splash screen
(setq inhibit-startup-screen t)

;; change initial  scratch message
(setq initial-scratch-message "Scratch me!!")

;; send line or region to R 
(global-set-key "\C-r" 'ess-eval-region-or-line-visibly-and-step)

;; set auto completion
(setq ess-use-auto-complete t)


;; disable auto-save and auto-backup
(setq auto-save-default nil)
(setq make-backup-files nil)
