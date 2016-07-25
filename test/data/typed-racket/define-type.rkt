#lang typed/racket/base

#| CT  |# (define-type Foo
#| CT  |#   (U 1 2 3
#| C   |#      4 5))

#| CT  |# (define (yolo (x : Foo))
#|  T  |#   : Foo
#| C   |#   x)
#|     |#
