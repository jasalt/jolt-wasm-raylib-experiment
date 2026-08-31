#!r6rs
(import (chezscheme))

;; The pinned Chez API releases and later reacquires `lock` around
;; condition-wait. The predicate loop makes this witness correct if a wait
;; wakes before the worker's state publication; no sleep or busy wait is used.
(scheme-start
 (lambda ()
  (let ([lock (make-mutex 'exp-014-lock)]
      [ready (make-condition 'exp-014-ready)]
      [state 0])
  (fork-thread
   (lambda ()
     (mutex-acquire lock)
     (set! state 73)
     (condition-signal ready)
     (mutex-release lock)))
  (mutex-acquire lock)
  (let wait-until-ready ()
    (unless (= state 73)
      (condition-wait ready lock)
      (wait-until-ready)))
  (mutex-release lock)
  (unless (= state 73)
    (assertion-violation 'EXP-014 "thread witness state mismatch" state))
  (display "THREAD-WITNESS-OK\n")
  (flush-output-port (current-output-port))
  (exit))))
