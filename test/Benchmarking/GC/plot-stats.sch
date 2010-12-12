(load "parse-stats-output.sch")
(load "gnuplot.sch")
(require 'list)

;; Example:
(define (show-example)
  (plot-stacked-bars 
   '("barf" "foo" "woof")
   '(("a1" 10 12 13) ("a2" 15 16 17) ("a3" 17 17 18) ("a4" 19 20 21)
     ("a5" 30 31 32) ("a6" 19 20 21))
   '(("b1" 20 22 23) ("b2" 25 26 27) ("b3" 27 27 28))
   '(("c1" 15 18 22) ("c2" 24 25 28) ("c3" 37 37 38)  ("c4" 30 32))
   ))

;; An L[i,X] is a Listof[X] of length i.

;; plot-stacked-bars
;;     : L[k,String] Listof[(cons String L[k,Number])] ... -> unspecified
;; renders each arg of form ((a1 .. a_k) (b1 .. b_k) ...)
(define (plot-stacked-bars bar-names . data-args)
  (define (massage-data-arg data bar-x-coord)
    (let* ((entries (append ; '(("")) ;; shifts bars over within group
                            data))
           (count (+ 1 (length entries)))
           (factor (/ 1 count))
           (numbers
            (map (lambda (e c)
                   (let ((x-coord (+ bar-x-coord (* c factor)))
                         (data-w/o-xtic (cdr e)))
                     (cons x-coord data-w/o-xtic)))
                 entries (map (lambda (i) (+ i 1)) (iota count))))
           (x-tics (map (lambda (e n)
                          (let ((xtic (car e)) (x-coord (car n)))
                            (list xtic x-coord)))
                        entries numbers)))
      (list (cons '() ;; breaks between data-args separate bar grps in plot
                  numbers)
            x-tics)))
  (let* ((count (length data-args))
         (max-group-width (+ 2 (apply max (map length data-args))))
         (data-and-xtics 
          (map massage-data-arg data-args (iota count)))
         (data-vals (apply append (map car data-and-xtics)))
         (xtics (apply append (map cadr data-and-xtics)))
         (box-width (inexact (min 0.5 (/ 1 max-group-width)))))
    (gnuplot/keep-files
     (lambda (data-file) 
       `((set style fill pattern 1 border)
         (set xrange \[ 0 : ,count \] )
         (set yrange \[ 0 : * \] )
         (set boxwidth ,box-width)
         (set xtics rotate (,(list->vector xtics)))
         (plot ,(list->vector 
                 (map (lambda (bar-name i) 
                        `(,data-file
                          using 1 : ,(+ i 2) with boxes
                          title ,bar-name))
                      (reverse bar-names)
                      (reverse (iota (length bar-names))))))))
     data-vals)
    xtics))


(define (plot-mmu . args)
  (gnuplot (lambda files
             `((plot ,(list->vector (map (lambda (file) `(,file with lines))
                                         files)))))
           (apply render-mmu args)))

;; A RenderedMMU is Listof[(list Nat Nat Nat Nat Nat Nat Nat)]
;; Each entry is (Window MinMut MaxMgr MaxMinor MaxMajor MaxSumz MaxRefine)

;; render-mmu2 :              -> RenderedMMU
;; render-mmu2 : MmuLogVector -> RenderedMMU
;; Each entry is (Window MinMut MaxMgr MaxMinor MaxMajor MaxSumz MaxRefine)
(define (render-mmu2 . args)
  (define (extract w real/cpu min/max category)
    (let* ((cat   (assq category (cdr w)))
           (times (assq min/max  (cdr cat)))
           (time  (cadr (memq real/cpu (cadr times)))))
      time))
  (define (window->stats w)
    (assert (eq? 'window (car w)))
    (let* ((window-size (cadr (assq 'size (cdr w))))
           (norm (lambda (t) (inexact (/ t window-size)))))
      (list window-size 
            (norm (extract w 'real 'min 'mutator))
            (norm (extract w 'real 'max 'memmgr))
            (norm (extract w 'real 'max 'minorgc))
            (norm (extract w 'real 'max 'majorgc))
            (norm (extract w 'real 'max 'summarize))
            (norm (extract w 'real 'max 'smircy)))))
  (define (mmu-log->window-data mmu-log)
    (map window->stats (cdr (vector->list mmu-log))))

  (let ((log (if (null? args) (extract-mmu) (car args))))
    (mmu-log->window-data log)))

;; plot-mmu2 :              -> unspecified
;; plot-mmu2 : MmuLogVector -> unspecified
(define (plot-mmu2 . args)
  (plot-mmu2/core (apply render-mmu2 args)))

;; plot-mmu/core : RenderedMMU -> unspecified
(define (plot-mmu2/core rmmu2 . args)
  (gnuplot (lambda (file)
             (define (min-line col title)
               `(,file using 1 : ,col 
                       axis x1y1
                       with lines 
                       title ,title))
             (define (max-line col title)
               `(,file using 1 : ,col 
                       axis x1y1
                       with linespoints
                       title ,title))
             `(,@(cond ((memq 'title: args) => 
                        (lambda (suffix)
                          (let ((title (cadr suffix)))
                            `((set title ,title)))))
                       (else '()))
               (set logscale x)
               (set yrange  \[ 0 : 1 \] )
               (set y2range \[ 1 : 0 \] )
               (plot #(,(min-line 2 "min mutator")
                       ,(max-line 3 "max misc")
                       ,(max-line 4 "max minor gc")
                       ,(max-line 5 "max major gc")
                       ,(max-line 6 "max summarize")
                       ,(max-line 7 "max rs refine")))))
           rmmu2))


;; A StackedBarSexp is a 
;;   (cons L[k,String] Listof[(cons String L[k,Number])])
;; where
;; An L[i,X] is a Listof[X] of length i.
;; 
;; see contract of plot-stacked-bars for a use of this class of data

;; However, StackedBarSexp is not what I ended up using below for
;; render-memory-usage and plot-memory-usage, b/c plot-stacked-bars is
;; intended for plotting the combination of many results.
;; 
;; One could use render-memory-usage after each benchmark run, writing
;; the s-exp result to a file, and then combine all of the results
;; (and pass that to plot-stacked-bars) after all desired benchmarks
;; have been run.

;; render-memory-usage : GclibStatVector -> (list L[k,String] L[k,Number])
;; render-memory-usage :                 -> (list L[k,String] L[k,Number])
(define (render-memory-usage . args)
  (let* ((vec (if (null? args) (extract-gclib-memstats) (car args)))
         (lst (vector->list vec))
         (get (lambda (key) (cadr (memq key lst)))))
    (let ((heap-max   (get 'heap_allocated_peak))
          (remset-max (get 'remset_allocated_peak))
          (summ-max   (get 'summ_allocated_peak))
          (smircy-max (get 'smircy_allocated_peak))
          (rts-max    (get 'rts_allocated_peak))
          (frag-max   (get 'heap_fragmentation_peak))
          (mem-max    (get 'mem_allocated_max))
          (accum*vals (let ((tot 0) (vals '()))
                        (list (lambda (n) 
                                (set! tot (+ tot n)) 
                                (set! vals (cons tot vals)))
                              (lambda () (reverse vals))))))
      (let* ((accum! (car accum*vals))
             (vallst (cadr accum*vals)))
        (for-each accum! 
                  (list heap-max rts-max remset-max
                        summ-max smircy-max frag-max))
        (list '("heap" "runtime" "remset"
                "summaries" "marker" "waste" "total")
              (append (vallst) (list mem-max)))))))

;; plot-memory-usage : GclibStatVector -> unspecified
;; plot-memory-usage :                 -> unspecified
(define (plot-memory-usage . args)
  (let ((rendered (apply render-memory-usage args)))
    (plot-stacked-bars (car rendered)
                       (list (cons "" (cadr rendered))))))

;; A LarcenyStatsSexp is a
;;   (list RuntimeInvokeString DateString BenchSexp ...)
;; A BenchSexp is a 
;;   (list FilenameSymbol BenchInvokeSexp TimeSexp MemstatsSexp)
;; A TimeSexp is a 
;;   (list Symbol (list TotalTimeSexp PauseTimeSexp))
;; A MemstatsSexp is a 
;;   (list Symbol Dataset)
;; 
;; TotalTimeSexp, PauseTimeSexp are (somewhat) self-describing
;; (they have descriptive symbols preceding their internal numeric stats)
;; 
;; MemstatsSexp and Dataset are also self-describing, but
;; in particular they are meant for use with the functions in
;; parse-stats-output.sch
;; 
;; In this file, the functions that will extract a useful
;; sub-component from a DataSet tend to be named with the prefix
;; "extract-", so searching for that string in the code should give
;; some guidance.  For example, render-memory-usage wants to receive
;; input formatted according to the result of extract-gclib-memstats

;; read-stats-sexp-log : String -> LarcenyStatsSexp
;; read-stats-sexp-log : TextInputPort -> LarcenyStatsSexp
;; reads s-exp log generated by bench-gc.scheme09.sh 
(define (read-stats-sexp-log x)
  (cond
   ((string? x) (call-with-input-file x read-stats-sexp-log))
   ((and (textual-port? x) (input-port? x))
    (let* ((context-string (read x))
           (date-string (read x))
           (bench-sexps 
            (let loop ()
              (let ((s (read x)))
                (cond ((eof-object? s) '())
                      (else (cons s (loop))))))))
      (append (list context-string date-string) 
              bench-sexps)))))

;; bench-sexp->benchmark-description : BenchSexp -> String
(define (bench-sexp->benchmark-description s)
  (let* ((filename-symbol (list-ref s 0))
         (bench-name (symbol->string filename-symbol))
         (bench-invoke-sexp (list-ref s 1))
         (param 
          (lambda (i)
            (list-ref bench-invoke-sexp i)))
         (param->string 
          (lambda (x)
            (cond 
             ((number? x) (number->string x))
             ((string? x) x)
             (else (error 'bench-sexp->benchmark-description
                          "unknown param ~a" x)))))
         (make-desc 
          (lambda (iters name . args)
            (apply string-append
                   (if (> iters 1) (number->string iters) "")
                   name
                   (map param->string args)))))
    (case filename-symbol
      ((earley nboyer sboyer)
       (make-desc (param 2) bench-name ":" (param 1)))
      ((gcbench) 
       (make-desc (param 1) bench-name ":" (param 2)))
      ((perm)
       (make-desc (param 1) bench-name ":" (param 2)))
      ((twobit) 
       (make-desc (param 2) bench-name ":" 
                  (let ((param1 (param 1)))
                    (cond 
                     ((equal? ''long  param1) "long")
                     ((equal? ''short param1) "short")
                     (else (error 'bench-sexp->benchmark-description
                                  "unknown twobit param ~a" param1))))))
      ((gcold)
       (make-desc        1  bench-name ":" (param 4)))
      (else
       (error 'bench-sexp->benchmark-description
              "unknown benchmark ~a" filename-symbol))
      )))

;; bench-sexp->time-sexp : BenchSexp -> TimeSexp
(define (bench-sexp->time-sexp s)
  (let ((filename-symbol   (list-ref s 0))
        (bench-invoke-sexp (list-ref s 1))
        (time-sexp         (list-ref s 2))
        (memstats-sexp     (list-ref s 3)))
    (assert (eq? 'last-stashed-stats (car time-sexp)))
    time-sexp))

;; bench-sexp->memstats-sexp : BenchSexp -> MemstatsSexp
(define (bench-sexp->memstats-sexp s)
  (let ((filename-symbol   (list-ref s 0))
        (bench-invoke-sexp (list-ref s 1))
        (time-sexp         (list-ref s 2))
        (memstats-sexp     (list-ref s 3)))
    (assert (eq? 'stats-dump (car memstats-sexp)))
    memstats-sexp))

;; bench-sexp->elapsed-times : BenchSexp -> (list (list Symbol Number) ...)
(define (bench-sexp->elapsed-times s)
  (let* ((time-sexp  (bench-sexp->time-sexp s))
         (total-sexp (car (cadr time-sexp)))
         (extract (lambda (key l) (cadr (memq key l))))
         (elapsed (lambda (key l) (extract 'elapsed (extract key l)))))
    (list (list 'overall:   (extract 'elapsed-time: total-sexp))
          (list 'gc:        (elapsed 'gc-total-time: total-sexp))
          (list 'mark:      (elapsed 'mark-time: total-sexp))
          (list 'summarize: (elapsed 'summarize-time: total-sexp)))))

;; bench-sexp->pause-times : BenchSexp -> (list (list Symbol Number) ...)
(define (bench-sexp->pause-times s)
  (let* ((time-sexp (bench-sexp->time-sexp s))
         (pause-sexp (cadr (cadr time-sexp)))
         (extract (lambda (key l) (cadr (memq key l))))
         (elapsed (lambda (key l) (extract 'elapsed (extract key l)))))
    (list (list 'gc:     (elapsed 'gc-max-pause: pause-sexp))
          (list 'cheney: (elapsed 'gc-max-cheney: pause-sexp))
          (list 'rsscan: (elapsed 'gc-max-remset-scan: pause-sexp)))))

;; A BenchDescriptionSexps is a Listof[BenchDescriptionSexp]
;;
;; A BenchDescriptionSexp is a (semi) self-describing s-exp

;; describe-stats-of-logfile : String -> BenchDescriptionSexps
(define (describe-stats-of-logfile filename)
  (let* ((real-filename 
          (cond ((file-exists? filename) filename)
                ((find-file-matching filename ".")
                 => (lambda (f)
                      (display "inferred logfile ")
                      (write f)
                      (newline)
                      f))
                (else
                 (error 'describe-stats-of-logfile 
                        "unknown logfile ~a" filename))))
         (stats-log (read-stats-sexp-log real-filename))
         (bench-entries (cddr stats-log))
         (bench-memory-usage
          (lambda (b)
            (extract-gclib-memstats
             (bench-sexp->memstats-dataset b))))
         (bench-utilization
          (lambda (b)
            (extract-mmu 
             (bench-sexp->memstats-dataset b))))
         (describe-bench
          (lambda (b)
            (list (bench-sexp->benchmark-description b) 
                  'overall: (bench-sexp->elapsed-times b)
                  'pauses: (bench-sexp->pause-times b)
                  'memory: (bench-memory-usage b)
                  'utilization: (bench-utilization b)
                  ))))
    (map describe-bench bench-entries)))

;; plot-stacked-bars consumes a list of bar names and then lists
;; of the data to plot.
;; 
;; Following helpers extract bars names from the data in each case,
;; put it at the front of the s-exp, and transpose each benchmark's
;; name into the value lists for the bars

;; bench-descriptions->elapsed-stacked-bars : BenchDescriptionSexps -> Sexp
(define (bench-descriptions->elapsed-stacked-bars bds)
  (let ((overall-time (lambda (bd) (cadr (memq 'overall: bd)))))
    (list
     '("mutator" "gc" "summarize" "mark")
     (map (lambda (bd)
            (let* ((ot (overall-time bd))
                   (ot-hdr (map car ot))
                   (ot-vals (map cadr ot)))
              (assert (equal? ot-hdr '(overall: gc: mark: summarize:)))
              ;; These timings are separate; they need to be
              ;; accumulated together to form a proper nest of times
              (let* ((val-overall (list-ref ot-vals 0))
                     (val-gc      (list-ref ot-vals 1))
                     (val-mark    (list-ref ot-vals 2))
                     (val-summ    (list-ref ot-vals 3))
                     (val-mut (- val-overall (+ val-gc val-mark val-summ)))
                     (val-gc*   (+ val-mut val-gc))
                     (val-summ* (+ val-gc* val-summ))
                     (val-mark* (+ val-summ* val-mark)))
                (list (car bd) val-mut val-gc* val-summ* val-mark*))))
          bds))))

;; bench-descriptions->pause-stacked-bars   : BenchDescriptionSexps -> Sexp
(define (bench-descriptions->pause-stacked-bars bds)
  (let ((pause-time (lambda (bd) (cadr (memq 'pauses: bd)))))
    (list
     '("remset scan" "cheney" "gc pause")
     (map (lambda (bd)
            (let* ((pt (pause-time bd))
                   (pt-hdr (map car pt))
                   (pt-vals (map cadr pt)))
              (assert (equal? pt-hdr '(gc: cheney: rsscan:)))
              ;; These timings are already nested
              (let* ((val-gc     (list-ref pt-vals 0))
                     (val-cheney (list-ref pt-vals 1))
                     (val-rsscan (list-ref pt-vals 2)))
                (list (car bd) val-rsscan val-cheney val-gc))))
          bds))))

;; bench-descriptions->mem-use-stacked-bars : BenchDescriptionSexps -> Sexp
(define (bench-descriptions->mem-use-stacked-bars bds)
  (let ((memory-use (lambda (bd) 
                      (render-memory-usage (cadr (memq 'memory: bd))))))
    (foldr (lambda (bd ents) 
             (let* ((mu (memory-use bd))
                    (ents-hdr (car ents))
                    (ents-vals (cadr ents))
                    (bd-hdr (car mu))
                    (bd-vals (cadr mu)))
               (assert (or (not ents-hdr) 
                           (equal? bd-hdr ents-hdr)))
               (list bd-hdr (cons (cons (car bd) bd-vals)
                                  ents-vals))))
           (list #f '())
           bds)))

;; bench-descriptions->mmu-data : BenchDescriptionSexps -> RenderedMMU
;; (takes the min/max as appropriate over all benchmarks in input)
(define (bench-descriptions->rendered-mmu2 bds)
  (collapse-rendered-mmus (bench-descriptions->rendered-mmu2* bds)))

;; collapse-rendered-mmus : Listof[RenderedMMU] -> RenderedMMU
;; (takes the min/max as appropriate over all mmu data in input)
(define (collapse-rendered-mmus rmmu2s)
  (foldr (lambda (rmmu2 rmmu2*)
           (map (lambda (entry entry2)
                  (map (lambda (e1 e2 op) (op e1 e2))
                       entry entry2
                       (list (lambda (w w2) 
                               (assert (= w w2)) w) ; window size
                             min ; mut
                             max ; mgr
                             max ; minor
                             max ; major
                             max ; sumz
                             max ; refine
                             )))
                rmmu2 rmmu2*))
         (car rmmu2s)
         (cdr rmmu2s)))

;; bench-descriptions->mmu-data : BenchDescriptionSexps -> Listof[RenderedMMU]
(define (bench-descriptions->rendered-mmu2* bds)
  (let* ((mmu (lambda (bd) 
                (render-mmu2 (cadr (memq 'utilization: bd)))))
         (rmmu2s (map mmu bds)))
    rmmu2s))

;; plot-bench-descriptions : Listof[BenchDescriptionSexp] -> unspecified
;; plot-bench-descriptions :                       String -> unspecified
(define (plot-bench-descriptions x)
  (cond
   ((string? x) 
    (plot-bench-descriptions (describe-stats-of-logfile x)))
   (else
    (let ((plot-one (lambda (s) (apply plot-stacked-bars s))))
      (for-each 
       plot-one
       (list (bench-descriptions->elapsed-stacked-bars x)
             (bench-descriptions->pause-stacked-bars x)
             (bench-descriptions->mem-use-stacked-bars x)))))))

;; bench-sexp->memstats-dataset : BenchSexp -> Dataset
(define (bench-sexp->memstats-dataset s)
  (cadr (bench-sexp->memstats-sexp s)))

;; some-benchmark : String -> BenchSexp
;; some-benchmark :       -> BenchSexp
;; utility fcn to ease input generation for other functions.
(define (some-benchmark . args)
  (let ((logfilename (if (null? args) 
                         (find-file-matching "bench-auto-log.*log" ".")
                         (car args))))
    (assert logfilename)
    (car (cddr (read-stats-sexp-log logfilename)))))

;; find-file-matching : RegexpString PathString -> Maybe[String]
(define (find-file-matching rs dir-to-search)
  (require 'file-system) ;; (avoiding doing require to last possible moment)
  (require 'regexp)
  (let ((results (filter (lambda (x) (regexp-match rs x))
                         (list-directory dir-to-search))))
    (cond
     ((null? results) #f)
     (else (car results)))))
