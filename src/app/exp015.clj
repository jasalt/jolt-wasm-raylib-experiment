(ns app.exp015
  (:require [jolt.ffi :as ffi]
            [app.witness :as witness]))

;; This deliberately uses only the signed scalar ABI proven by EXP-006. The C
;; facade owns Raylib's browser frame loop; Jolt selects its initial scene.
;; `declare` teaches generic Clojure tooling about jolt.ffi/defcfn's generated Var.
(declare project-set-scene)
(ffi/defcfn project-set-scene "project_set_scene" [:int32] :int32)

(defn -main [& args]
  (when-not (= 1 (project-set-scene 1))
    (throw (ex-info "EXP-015 scene selection failed" {})))
  (apply witness/-main args)
  (println "EXP-015-JOLT-RAYLIB-SCENE-SELECTED"))
