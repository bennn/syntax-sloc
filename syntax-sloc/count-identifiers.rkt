#lang racket/base

(provide identifiers-from)

(require drracket/check-syntax
         lang-file/read-lang-file
         racket/class
         racket/set
         setup/collects)

;; =============================================================================

;; Represents prefix of a collects path.
;; Used to filter results from `path->collects-relative`.
;; (Listof Bytes)
(define current-only-in (make-parameter '()))

;; Overrides the `current-annotations` parameter for check-syntax.
(define collector%
  (class (annotations-mixin object%)
    (super-new)

    (define ids
      (mutable-set))

    (define/public (collected-identifiers)
      (set->list ids))

    ;; Every non-#f syntax object is interesting
    (define/override (syncheck:find-source-object stx)
      stx)

    ;; If `filename` is from a collection matching `current-only-in`,
    ;;  we record the identifier.
    (define/override (syncheck:add-jump-to-definition source-obj start end id filename submods)
      (when (collects-prefix? (path->collects-relative filename) (current-only-in))
        (set-add! ids source-obj)))))

;; True if `c-path` is a 'collects path
;;  and `bytes` is a prefix of the byte strings following 'collects
; (U Path-String (Pairof 'collects Collects-Relative)) (Listof Bytes) -> Boolean
(define (collects-prefix? c-path bytes)
  (and (eq? (car c-path) 'collects)
       (let prefix? ([c-path (cdr c-path)]
                     [bytes bytes])
         (cond
          [(null? bytes)
           #t]
          [(null? c-path)
           #f]
          [else
           (and (bytes=? (car c-path) (car bytes))
                (prefix? (cdr c-path) (cdr bytes)))]))))

(define (identifiers-from path-string #:only-in [only-in #f])
  (define annotations (new collector%))
  (define ns (make-base-namespace))
  (define-values (add-syntax done)
    (make-traversal ns #f))
  (parameterize ([current-annotations annotations]
                 [current-namespace ns]
                 [current-only-in (or only-in '())])
    (add-syntax (expand (read-lang-file path-string)))
    (done))
  (send annotations collected-identifiers))

