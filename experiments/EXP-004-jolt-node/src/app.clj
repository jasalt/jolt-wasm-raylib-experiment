(ns app)
(defn -main []
  (println "EXP-004-JOLT-OK" (assoc {:frame 41} :frame 42) ["unicode" "😀"]))
