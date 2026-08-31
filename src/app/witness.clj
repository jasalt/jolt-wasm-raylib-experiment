(ns app.witness)

(defn allocation-pressure []
  (loop [n 20000 acc 0]
    (if (zero? n)
      acc
      (recur (dec n) (+ acc (count (conj [n] n)))))))

(defn -main [& _]
  (println "EXP-004-JOLT-PB-OK")
  (println {:unicode "λ-東京" :collection (conj [1 2] 3)})
  (println "allocation" (allocation-pressure)))
