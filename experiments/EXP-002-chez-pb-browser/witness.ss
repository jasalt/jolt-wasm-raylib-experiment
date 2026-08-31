(define (run-browser-witness)
  (display "EXP-002-PB-BROWSER-OK\n")
  (display (machine-type))
  (newline)
  (display (+ 40 2))
  (newline)
  (exit))

(scheme-start run-browser-witness)
