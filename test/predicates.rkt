#lang typed/racket/base (module+ test

;; End-to-end unit tests for syntax-sloc
;;
;; Parses whole `.rkt` files for their line counts
;;  and compares the automated result to hand-written annotations in the files.

(require
  typed/rackunit
  racket/runtime-path
  syntax/parse/define
  syntax-sloc/lang-file-sloc
  (only-in racket/string string-contains?)
  (for-syntax racket/base))

(define-type Stx-Pred (U #f (-> (Syntaxof Any) Boolean)))

;; IMPORTANT: to test a collection, make sure ther start of every line is:
;;     #| TAG |#
;;   where `TAG` is the symbol next to your predicate in the list `predicates`.
;;
;;  For example, every line of Typed Racket type annotation, like:
;;    (: foo (-> Integer Integer))
;;  should be annotated as:
;;    #| T |# (: foo (-> Integer Integer))
;;  to tell the unit tester "if the `is-type-ann?` predicate doesn't recognize
;;  this line, we have a problem!"
(: predicates : (Listof (List Symbol (Listof Bytes))))

(define predicates '(
                 (T (#"typed-racket"))
                 (R (#"racket" #"contract"))
                ))

;; -----------------------------------------------------------------------------

;; For each predicate, compare the hand-annotated count of relevant lines
;;  to the number of lines accepted by the predicate.
(: check-sloc/only-in : Path-String -> Void)
(define (check-sloc/only-in path)
  (for ([tag+oi (in-list predicates)]) : Void
    (define-values (tag only-in) (apply values tag+oi))
    (define handwritten-sloc (count-tagged-lines tag path))
    (define automatic-sloc (lang-file-sloc path #:only-in only-in))
    (check-equal? automatic-sloc handwritten-sloc
      (format "~a lines of code in '~a'" tag path))))

;; Count the number of hand-annotated lines in a file.
(: count-tagged-lines : Symbol Path-String -> Natural)
(define (count-tagged-lines tag-sym path)
  (define tag-str (symbol->string tag-sym))
  (define tags-rx
    (pregexp (string-append "^(\\s)?#\\|(.+)\\|#\\s")))
  (with-input-from-file path
    (lambda ()
      (for/sum : Natural
               ([ln (in-lines)])
      (define m (regexp-match tags-rx ln))
      (if (and m (string-contains? (or (caddr m) (error 'rx)) tag-str))
        1
        0)))))

;; -----------------------------------------------------------------------------

(define-simple-macro (define-sloc-test-file path* ...)
  #:with (id* ...) (for/list ([_p (in-list (syntax-e #'(path* ...)))]) (gensym 'path))
  (begin (begin (define-runtime-path id* path*) (check-sloc/only-in id*)) ...))

(define-sloc-test-file
  "data/contract/simple.rkt"
  "data/contract/define.rkt"
  "data/contract/redefine.rkt"
  "data/contract/rename-in.rkt"
  "data/contract/prefix-in.rkt"
  "data/contract/quoted.rkt"
  "data/contract/submodule.rkt")

(define-sloc-test-file
  #;"data/typed-racket/annotate.rkt"
  #;"data/typed-racket/define.rkt"
  #;"data/typed-racket/define-type.rkt"
  "data/typed-racket/prefix-in.rkt"
  #;"data/typed-racket/quoted.rkt"
  #;"data/typed-racket/redefine.rkt"
  #;"data/typed-racket/rename-in.rkt"
  #;"data/typed-racket/simple.rkt"
  #;"data/typed-racket/small.rkt"
  #;"data/typed-racket/submodule.rkt")

)
