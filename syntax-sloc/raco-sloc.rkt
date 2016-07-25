#lang typed/racket/base

;; Command-line interface for computing SLOC

(require syntax-sloc
         (only-in typed/syntax-sloc/read-lang-file lang-file? lang-file-lang)
         (only-in racket/port with-input-from-string)
         (only-in racket/string string-join string-prefix? string-suffix?)
         (only-in racket/format ~a ~r))

;; -----------------------------------------------------------------------------

(define SLOC-HEADER "SLOC~a\tSource")

(define MAX-PATH-WIDTH 40) ;; characters

;; Get SLOC for `src`, output a string with pretty-printed results
(: format-sloc : (Path-String -> Natural) Path-String -> String)
(define (format-sloc get-sloc src)
  (string-append (~r (get-sloc src) #:min-width 4)
                 "\t"
                 (format-filepath src)))

;; Print a filepath, truncate if too long
(: format-filepath : Path-String -> String)
(define (format-filepath src)
  (~a src #:max-width MAX-PATH-WIDTH
          #:limit-marker "..."
          #:limit-prefix? #t))

(: missing-sloc : String -> String)
(define (missing-sloc src)
  (string-append " N/A" "\t" src))

(: lang-line-match? : Regexp Path-String -> Boolean)
(define (lang-line-match? px src)
  (define lang-line (lang-file-lang src))
  (and lang-line (regexp-match-exact? px lang-line)))

(: only-in->header : (U #f (Listof Bytes)) -> String)
(define (only-in->header bytes)
  (if bytes
    (format "(~a)" (string-join (map bytes->string/utf-8 bytes) "/"))
    ""))

;; -----------------------------------------------------------------------------

(module+ main
  (require racket/cmdline)
  (define *lang-file-pregexp* : (Parameterof (U #f Regexp)) (make-parameter #f))
  (define *mp-string* : (Parameterof (U #f String)) (make-parameter #f))
  (define *only-in* : (Parameterof (U #f (Listof Bytes))) (make-parameter #f))
  (command-line
   #:program "syntax-sloc"
   #:once-each
   [("-l" "--lang")
    lang-pregexp
    "Only count files with a matching #lang line"
    (*lang-file-pregexp* (pregexp (assert lang-pregexp string?)))]
   #:once-any
   [("--contract")
    "Only count identifiers from racket/contract"
    (*only-in* '(#"racket" #"contract"))]
   [("--type-ann")
    "Only count identifiers from typed/racket"
    (*only-in* '(#"typed-racket"))]
   #:args FILE-OR-DIRECTORY
   (define px (*lang-file-pregexp*))
   (printf SLOC-HEADER (only-in->header (*only-in*)))
   (newline)
   (define matching-lang? : (-> Path-String Boolean)
     (if px
         (lambda ((src : Path-String)) (lang-line-match? px src))
         (lambda ((src : Path-String)) #t)))
   (define only-in (*only-in*))
   (define (directory-sloc/filter (src : Path-String)) : Natural
     (directory-sloc src #:use-file? matching-lang? #:only-in only-in))
   (define (lang-file-sloc/filter (src : Path-String)) : Natural
     (lang-file-sloc src #:only-in only-in))
   (for ([any (in-list FILE-OR-DIRECTORY)])
     (define src (assert any string?))
     (displayln
       (cond
        [(directory-exists? src)
         (format-sloc directory-sloc/filter src)]
        [(and (lang-file? src) (matching-lang? src))
         (format-sloc lang-file-sloc/filter src)]
        [else
         (missing-sloc src)])))))
