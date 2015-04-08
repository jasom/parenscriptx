(in-package :parenscriptx/example)

;;; Helper macro for this-preserving lambda
(ps:defpsmacro tlambda (args &body b)
  `(chain
    (lambda ,args ,@b)
    (bind this)))



(defun start-server ()
  (hunchentoot:start (make-instance 'hunchentoot:easy-acceptor :port 4242)))

(defun encode-json-list-to-string (list)
  (let ((json::*json-list-encoder-fn* #'json::encode-json-list-explicit-encoder))
    (json:encode-json-to-string (cons :list list))))

(hunchentoot:define-easy-handler (comments :uri "/comments.json") ()
  (setf (hunchentoot:content-type*) "application/json")
  (let ((comments
	 (if (probe-file "comments.json")
	     (mapcar #'alexandria:alist-hash-table
		     (with-open-file (file "comments.json"
					   :direction :input)
		       (cl-json:decode-json file)))
	     (list))))
    (when (eql (hunchentoot:request-method*) :post)
      (with-open-file (file "comments.json" :direction :output
			    :if-exists :supersede)
	(cl-json:encode-json
	 (setf comments
	       (append
		comments
		(list (alexandria:alist-hash-table (hunchentoot:post-parameters*)))))
	 file)))
    (encode-json-list-to-string comments)))

(hunchentoot:create-static-file-dispatcher-and-handler
 "css/base.css"
 (asdf:system-relative-pathname :parenscriptx/example "example/base.css")
 "text/css")

(hunchentoot:define-easy-handler (index :uri "/index.html") ()
  (with-html-output-to-string (stream nil :prologue "<!DOCTYPE html>")
    (:html
     (:head
      (:title "Hello React")
      (:link :rel "stylesheet" :href "css/base.css")
      (:script :src "https://cdnjs.cloudflare.com/ajax/libs/react/0.13.1/react.js")
      (:script :src "https://cdnjs.cloudflare.com/ajax/libs/react/0.13.1/JSXTransformer.js")
      (:script :src "https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js")
      (:script :src "https://cdnjs.cloudflare.com/ajax/libs/showdown/0.3.1/showdown.min.js"))
     (:body
      (:div :id "content")
      (:script
       :type "text/jsx;harmony=true"
       (ps-to-stream stream
;;; var converter = new Showdown.converter();
     (var *converter* (new (chain *showdown (converter))))

;;;var Comment = React.createClass({
;;;                render: function() {
;;;                var rawMarkup = converter.makeHtml(this.props.children.toString());
;;;                return (
;;;                    <div className="comment">
;;;                         <h2 className="commentAuthor">
;;;                         {this.props.author}
;;;                         </h2>
;;;                         <span dangerouslySetInnerHTML={{__html: rawMarkup}} />
;;;                         </div>
;;;                         );
;;;                }
;;;                });
     (defreact *comment
         render (lambda ()
		  (let ((raw-markup
			 (chain *converter* (make-html (chain this props children (to-string))))))
		    (htm
		     (:div
		      :class-name "comment"
		      (:h2
		       :class-name "comment-author"
		       ({ (@ this props author)))
		      (:span :dangerously-set-inner-h-t-m-l
			     ({(create __html raw-markup))))))))

;;;var CommentBox = React.createClass({
;;;                   loadCommentsFromServer: function() {
;;;                   $.ajax({
;;;                      url: this.props.url,
;;;                      dataType: 'json',
;;;                      success: function(data) {
;;;                      this.setState({data: data});
;;;                      }.bind(this),
;;;                      error: function(xhr, status, err) {
;;;                      console.error(this.props.url, status, err.toString());
;;;                      }.bind(this)
;;;                      });
;;;                   },
;;;                   handleCommentSubmit: function(comment) {
;;;                   var comments = this.state.data;
;;;                   comments.push(comment);
;;;                   this.setState({data: comments}, function() {
;;;                            // `setState` accepts a callback. To avoid (improbable) race condition,
;;;                            // `we'll send the ajax request right after we optimistically set the new
;;;                            // `state.
;;;                            $.ajax({
;;;                                   url: this.props.url,
;;;                                   dataType: 'json',
;;;                                   type: 'POST',
;;;                                   data: comment,
;;;                                   success: function(data) {
;;;                                   this.setState({data: data});
;;;                                   }.bind(this),
;;;                                   error: function(xhr, status, err) {
;;;                                   console.error(this.props.url, status, err.toString());
;;;                                   }.bind(this)
;;;                                   });
;;;                            });
;;;                   },
;;;                   getInitialState: function() {
;;;                   return {data: []};
;;;                   },
;;;                   componentDidMount: function() {
;;;                   this.loadCommentsFromServer();
;;;                   setInterval(this.loadCommentsFromServer, this.props.pollInterval);
;;;                   },
;;;                   render: function() {
;;;                   return (
;;;                       <div className="commentBox">
;;;                        <h1>Comments</h1>
;;;                        <CommentList data={this.state.data} />
;;;                        <CommentForm onCommentSubmit={this.handleCommentSubmit} />
;;;                        </div>
;;;                        );
;;;                   }
;;;                   });

     (defreact *comment-box
         load-comments-from-server (lambda ()
                     (chain $
                        (ajax
                         (create
                          url (@ this props url)
                          data-type "json"
                          success (tlambda (data)
                               (chain this (set-state (create data data))))
                          error (tlambda (xhr status err)
                             (chain console
                                (error
                                 (@ this props url)
                                 status
                                 (chain err (to-string)))))))))
         handle-comment-submit (lambda (comment)
                     (let ((comments (@ this state data)))
                       (chain comments (push comment))
                       (chain this
                          (set-state
                           (create data comments)
                           (lambda ()
                         (chain $
                            (ajax
                             (create
                              url (@ this props url)
                              data-type :json
                              type "POST"
                              data comment
                              success
                              (tlambda (data)
                                (chain this
                                   (set-state
                                    (create data data))))
                              error
                              (tlambda (xhr status error)
                                (chain console
                                   (error (@ this props url)
                                      status
                                      (chain err to-string))))))))))))
         get-initial-state (lambda () (create data (array)))
         component-did-mount (lambda ()
                   (chain this (load-comments-from-server))
                   (set-interval (@ this load-comments-from-server)
                         (@ this props poll-interval)))
         render (lambda ()
              (htm
               (:div :class-name "commentBox"
                 (:h1 "Comments")
                 (:*comment-list :data ({(@ this state data)))
                 (:*comment-form :on-comment-submit
                        ({(@ this handle-comment-submit)))))))

;;;var CommentList = React.createClass({
;;;                    render: function() {
;;;                    var commentNodes = this.props.data.map(function(comment, index) {
;;;                                           return (
;;;                                               // `key` is a React-specific concept and is not mandatory for the
;;;                                                  // purpose of this tutorial. if you're curious, see more here:
;;;                                                  // http://facebook.github.io/react/docs/multiple-components.html#dynamic-children
;;;                                                  <Comment author={comment.author} key={index}>
;;;                                                  {comment.text}
;;;                                                  </Comment>
;;;                                                  );
;;;                                           });
;;;                    return (
;;;                        <div className="commentList">
;;;                         {commentNodes}
;;;                         </div>
;;;                         );
;;;                    }
;;;                    });

     (defreact *comment-list
         render (lambda ()
              (let ((comment-nodes (chain
                        this props data
                        (map (lambda (comment index)
			       (htm
				(:*comment
				 :author ({(@ comment author))
				 :key ({ index)
				 ({(@ comment text)))))))))
		(htm
		 (:div
		  ({ comment-nodes))))))

;;;var CommentForm = React.createClass({
;;;                    handleSubmit: function(e) {
;;;                    e.preventDefault();
;;;                    var author = React.findDOMNode(this.refs.author).value.trim();
;;;                    var text = React.findDOMNode(this.refs.text).value.trim();
;;;                    if (!text || !author) {
;;;                    return;
;;;                    }
;;;                    this.props.onCommentSubmit({author: author, text: text});
;;;                    React.findDOMNode(this.refs.author).value = '';
;;;                    React.findDOMNode(this.refs.text).value = '';
;;;                    },
;;;                    render: function() {
;;;                    return (
;;;                        <form className="commentForm" onSubmit={this.handleSubmit}>
;;;                          <input type="text" placeholder="Your name" ref="author" />
;;;                          <input type="text" placeholder="Say something..." ref="text" />
;;;                          <input type="submit" value="Post" />
;;;                          </form>
;;;                          );
;;;                    }
;;;                    });
     (defreact *comment-form
	 handle-submit (lambda (e)
			 (let ((author (chain *react (find-d-o-m-node (@ this refs author))
					      value (trim)))
			       (text (chain *react (find-d-o-m-node (@ this refs text))
					    value (trim))))
			   (chain e (prevent-default))
			   (when (and text author)
			     (chain this props (on-comment-submit
						(create author author text text)))
			     (setf
			      (chain *react (find-d-o-m-node (@ this refs author)) value)
			      ""
			      (chain *react (find-d-o-m-node (@ this refs text)) value)
			      ""))))
	 render (lambda ()
		  (htm
		   (:form
		    :class-name "commentForm"
		    :on-submit ({(@ this handle-submit))
		    (:input :type "text"
			    :placeholder "Your name"
			    :ref "author")
		    (:input :type "text"
			    :placeholder "Say something..."
			    :ref "text")
		    (:input :type "submit" :value "Post")))))

;;;React.render(
;;;         <CommentBox url="comments.json" pollInterval={2000} />,
;;;             document.getElementById('content')
;;;             );

     (chain *React (render
		    (htm
		     (:*comment-box :url "comments.json"
				    :poll-interval ({ 2000)))
		    (chain document (get-element-by-id "content"))))))))))
