(ns app.witness-test
  (:require [clojure.test :refer [deftest is run-tests]]))

(defn- advance [state delta]
  (assoc state :frame (+ (:frame state) delta)))

(deftest advance-preserves-state-and-updates-frame
  (is (= {:frame 5 :label "diagnostic"}
         (advance {:frame 3 :label "diagnostic"} 2))))

(defn -main []
  (let [{:keys [fail error]} (run-tests 'app.witness-test)]
    (when (pos? (+ fail error))
      (throw (ex-info "native witness failed" {:fail fail :error error})))
    (println "native Jolt witness: PASS")))
