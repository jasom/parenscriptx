;;;; parenscriptx.lisp

(in-package #:parenscriptx)
(declaim (optimize (speed 3) (space 0) (debug 0)))

;;; "parenscriptx" goes here. Hacks and glory await!

(defun split-tag-parts (tree)
  (loop with tag = (car tree)
     for rest on (cdr tree) by #'cddr
     while (keywordp (car rest))
     collect (ps::encode-js-identifier (string (car rest))) into attrs
     collect (if (symbolp (cadr rest))
		 (ps::encode-js-identifier (string (cadr rest)))
		 (cadr rest))
     into attrs
     finally (return (values tag attrs rest))))

(defun html-element-p (keyword)
  (notany #'upper-case-p (ps::encode-js-identifier (string keyword))))

(parenscript:defpsmacro htm (&body trees)
  (if (> (length trees) 1)
  `(progn ,@(mapcar #'psx-htm-item trees))
  (psx-htm-item (car trees))))

(defun psx-htm-item (tree)
  (if (and (consp tree) (keywordp (car tree)))
      (multiple-value-bind (tag attrs body)
	  (split-tag-parts tree)
	`(ps:chain
	  *react
	  (create-element
	   ,(if (html-element-p tag)
		(ps::encode-js-identifier (string tag))
		(intern (string tag) *package*))
	   (ps:create ,@attrs)
	   ,@(loop for item in body
		  collect `(htm ,item)))))
      tree))

(ps:defpsmacro defreact (name &rest args)
  `(ps:var ,name 
	       (ps:chain *react (create-class (ps:create ,@args)))))
   

;;; The following two macros are for backwards-compatibility
;;; It used to be required that parenscript inside htm be
;;; enclosed in a { macro.
(parenscript:defpsmacro { (b) b)

(parenscript:defpsmacro cl-who:esc (item)
  item)
