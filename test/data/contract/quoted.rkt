#lang racket

#| C R |# (define/contract x
#| C   |#   integer?
#| C   |#   1)

#| C   |# (define y 'any/c)  ;; should not count
#| C   |# (define z "any/c")

#| C   |# (provide
#|   R |#   (contract-out
#|   R |#     [y (-> natural-number/c natural-number/c)]))

