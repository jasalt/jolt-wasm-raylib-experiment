(ns app.exp014
  (:require [app.witness :as witness]))

(defn -main [& args]
  (apply witness/-main args)
  (println "EXP-014-JOLT-COMPLETE"))
