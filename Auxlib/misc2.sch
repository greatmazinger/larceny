; More useful procedures.
; $Id$

; Read-substring and write-substring can be optimized by plugging into 
; the I/O system; for now, they are useful abstractions.

; Returns #<eof> if no characters were read, otherwise the number of
; characters that were read into the string.

(define (read-substring buf start end . rest)
  (let ((port (cond ((null? rest) (current-input-port))
		    ((null? (cdr rest)) (car rest))
		    (else (error "read-substring: too many arguments.")))))
    (let loop ((i start))
      (if (= i end)
	  (- end start)
	  (let ((c (read-char port)))
	    (if (eof-object? c)
		(if (= i start)
		    c
		    (- i start))
		(begin (string-set! buf i c)
		       (loop (+ i 1)))))))))

; Returns something unspecified.

(define (write-substring buf start end . rest)
  (let ((port (cond ((null? rest) (current-input-port))
		    ((null? (cdr rest)) (car rest))
		    (else (error "read-substring: too many arguments.")))))
    (do ((i start (+ i 1)))
	((= i end))
      (write-char (string-ref buf i) port))))

; Environment switching procedures.  They will be available in all
; environments that inherit from this environment.
;
; FIXME: need to interact with the repl prompt to show the environment name
; in the prompt?

; 'Go to the default environment'

(define *user-env* (interaction-environment))

; 'Go to environment'

(define (ge env)
  (interaction-environment env))

; eof
