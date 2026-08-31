(define project-set-scene
  (foreign-procedure "project_set_scene" (integer-32) integer-32))
(define (run-witness)
  (unless (= (project-set-scene 2) 2)
    (error 'EXP-007 "scene selection failed"))
  (display "EXP-007-CHEZ-FACADE-OK scene=2\n"))
(scheme-start run-witness)
