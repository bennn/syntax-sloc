#lang racket/base

#| C    |# (module a racket/base
#| C    |#   (require racket/contract)
#| C  R |#   (define/contract x integer? 2))
#|      |#
#| C    |# (module* b racket/base
#| C    |#   (require (rename-in racket/string (string-join any/c)))
#| C    |#   (define y any/c))