;;;; parenscriptx.lisp

(in-package #:parenscriptx)
(declaim (optimize (speed 3) (space 0) (debug 0)))

;;; "parenscriptx" goes here. Hacks and glory await!

(defmethod cl-who:convert-tag-to-string-list :around ((tag symbol) attr body fns)
  (let* ((tn (symbol-name tag))
	 (tnf (if (char= (elt tn 0) #\*)
		  (ps::encode-js-identifier tn)
		  (string-downcase tn)))
	 (cl-who:*downcase-tokens-p* t)
	 (attrs
	  (loop for item in attr
	     when (and (consp (cdr item)) (eql (second item) '{))
	     collect (cons (ps::encode-js-identifier (string (car item))) 'placeholder)
	     else collect (cons (ps::encode-js-identifier (string (car item))) (cdr item))))
	 (cl-who:*downcase-tokens-p* nil)
	 (result
	  (call-next-method tnf attrs body fns)))
  (loop
     with braces = (remove-if-not
		    (lambda (x) (and (consp (cdr x)) (eql (second x) '{)))
		    attr)
     for item in result
     ;do (princ item) (terpri)
     unless (and (consp item)
		 (eql (car item) 'let)
		 (eql (second (first (second item))) 'placeholder))
     collect item
     else
       collect (format nil " ~A={" (ps::encode-js-identifier (string (caar braces)))) and
     collect (with-output-to-string (parenscript::*psw-stream*)
	       (parenscript::parenscript-print
		(parenscript::compile-expression (third (pop braces))) t))
       and collect "}")))
       

(defmethod parenscript::ps-print% ((op (eql 'htm)) args)
  (funcall (compile nil `(lambda ()
		       (cl-who:with-html-output (parenscript::*psw-stream*) ,@args)))))

(parenscript::define-expression-operator htm (&rest args) `(htm ,@args))

(defmacro { (&body b)
  `(progn
     (write-char #\{ parenscript::*psw-stream*)
     (parenscript::parenscript-print
      (parenscript::compile-expression ',(car b)) t)
     (write-char #\} parenscript::*psw-stream*)))

(ps:defpsmacro defreact (name &rest args)
  `(ps:var ,name 
	       (ps:chain *react (create-class (ps:create ,@args)))))
   
