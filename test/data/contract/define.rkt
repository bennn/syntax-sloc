#lang racket

#| C   |# (define foo/c
#| C R |#   (or/c boolean?
#| C   |#         integer?))

#| C R |# (define/contract (yolo x)
#| C R |#   (-> foo/c foo/c)
#| C   |#   x)
#|     |#
#| C R |# (define/contract (wepa x)
#| C R |#   (-> foo/c foo/c)
#| C   |#   (yolo x))

