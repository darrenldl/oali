#!/usr/bin/racket
#lang racket

(module+ main
  (define files-or-dirs
    (vector->list (current-command-line-arguments)))
  (disable-boost files-or-dirs))

(define/contract (list-of-strings? lst)
  (-> list? boolean?)
  (match lst
    [(list)       #t]
    [(list a b ...) (and (string? a)
                       (list-of-strings? b))]
    ))

(define/contract (filter-boost str)
  (-> string? string?)
  (regexp-replace* #rx"(Boost\\].+?volume =) ([a-zA-Z]*)"
                          str
                          "\\1 zero"))

(define/contract (disable-boost file-list)
  (-> list-of-strings? any)
    (match file-list
      [(list)              (void)]
      [(list cur rest ...) (begin
                             (cond
                             [(file-exists?      cur) (let ([content ""])
                                                        (call-with-input-file cur
                                                          #:mode 'text
                                                          (lambda (in)
                                                            (set! content (port->string in))))
                                                        (set! content
                                                              (filter-boost content))
                                                        ;(display content)
                                                        (call-with-output-file cur
                                                          #:exists 'update
                                                          (lambda (out)
                                                            (display content out))))]
                             [(directory-exists? cur) (let ([file-list (directory-list cur)])
                                                        (disable-boost file-list))])
                             (disable-boost rest))]))
