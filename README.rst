Parenscript X
=============

A simple tool for aiding with creating React UIs in parenscript
---------------------------------------------------------------

Hello World (:use parenscript parenscriptx cl-who):

.. code:: lisp
  (with-html-output-to-string (stream nil :prologue "<!DOCTYPE html>")
    (:html
     (:head
      (:title "Hello React")
      (:script :src "https://cdnjs.cloudflare.com/ajax/libs/react/0.14.3/react.js")
      (:script :src "https://cdnjs.cloudflare.com/ajax/libs/react/0.14.3/react-dom.min.js")
      (:body
       (:div :id "content")
       (:script
	(ps-to-stream stream
;;; var converter = new Showdown.converter();
	  (defreact *hello-world
	      render (lambda () (htm
				 (:div (+ "Hello " (@ this props name) "!")))))
	  (chain *React-d-o-m (render
			       (htm
				(:*hello-world :name "World"))
			       (chain document (get-element-by-id "content"))))))))))

This allows cl-who style elements inside parenscript.  The symbol
``cl-who:htm`` is used to introduce html literals into javascript.
You must prefix all react class names with an asterisk; parenscript
will turn ``*camel-case-name`` into ``CamelCaseName`` so this follows
the convention of initial capital letters for react classes, and
allows for HTML to introduce new element names without needing to
update this library.

Lastly ``defreact`` is a convenience wrapper for generating "var Foo = React.createClass(...)" forms; the body is alternating key/value pairs for the react object that is created.

There is `a more full-featured example using
hunchentoot`__

__: example/code.lisp
