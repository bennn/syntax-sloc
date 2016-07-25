#lang typed/racket/base

;; DO NOT modify this file without also updating the SLOC count in:
;;  - the test at the bottom of this file
;;  - the example in the README.md file

(provide lang-file-sloc)

(require "syntax-sloc.rkt"
         racket/set
         typed/syntax-sloc/read-lang-file)

(require/typed syntax-sloc/count-identifiers
  (identifiers-from (->* [Path-String] [#:only-in (Listof Bytes)] (Listof Identifier))))

(module+ test
  (require typed/rackunit
           racket/runtime-path))

(: lang-file-sloc : Path-String [#:only-in (U #f (Listof Bytes))] -> Natural)
(define (lang-file-sloc path-string #:only-in [only-in #f])
  (if only-in
    (set-count
      (list->set (map syntax-line (identifiers-from path-string #:only-in only-in))))
    (syntax-sloc (read-lang-file path-string))))

(module+ test
  (define-runtime-path this-file "lang-file-sloc.rkt")
  (check-equal? (lang-file-sloc this-file)
                20))

