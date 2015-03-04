;;;; parenscriptx.asd

(asdf:defsystem #:parenscriptx
  :description "Tool for generating React XJS templates"
  :author "Jason Miller <aidenn0@geocities.com>"
  :license "MIT/X11"
  :depends-on (#:cl-who
               #:parenscript
               #:alexandria
               #:split-sequence)
  :serial t
  :components ((:file "package")
               (:file "parenscriptx")))

