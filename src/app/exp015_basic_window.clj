(ns app.exp015-basic-window
  (:require [jolt.ffi :as ffi]
            [app.witness :as witness]))

;; This deliberately uses only the signed scalar ABI proven by EXP-006. The C
;; facade owns Raylib's browser frame loop; Jolt selects its initial scene.
;; `declare` teaches generic Clojure tooling about jolt.ffi/defcfn's generated Var.
(declare project-set-scene project-set-input-mode)
(ffi/defcfn project-set-scene "project_set_scene" [:int32] :int32)
(ffi/defcfn project-set-input-mode "project_set_input_mode" [:int32] :int32)

(defn -main [& args]
  (when-not (= 1 (project-set-input-mode 1))
    (throw (ex-info "EXP-015 input mode selection failed" {})))
  (when-not (= 3 (project-set-scene 3))
    (throw (ex-info "EXP-015 scene selection failed" {})))
  (apply witness/-main args)
  (println "EXP-015-JOLT-RAYLIB-SCENE-SELECTED"))
