(ns app.exp016
  (:require [jolt.ffi :as ffi]
            [app.witness :as witness]))

;; EXP-016 defines the complete visual command stream in Jolt. The C host owns
;; only Raylib calls, browser scheduling, and owner-thread input polling.
(declare project-scene-write project-scene-commit)
(ffi/defcfn project-scene-write "project_scene_write" [:int32 :int32] :int32)
(ffi/defcfn project-scene-commit "project_scene_commit" [:int32] :int32)

(def ^:private scene-commands
  ;; Each command has ten signed scalar fields:
  ;; op x y width-or-radius height red green blue input-x input-y.
  ;; op: 1 background, 2 rectangle, 3 circle.
  ;; input: 0 fixed, 1 mouse coordinate, 2 ArrowRight adds 100 pixels.
  [[1 0   0   0   0   20  24  41  0 0]
   [2 36  32  648 296 35  45  74  0 0]
   [3 180 150 72  0   230 41  55  1 1]
   [2 320 88  300 124 230 41  55  2 0]])

(defn- upload-scene! []
  (let [values (vec (apply concat scene-commands))]
    (doseq [index (range (count values))]
      (let [value (nth values index)]
        (when-not (= value (project-scene-write index value))
          (throw (ex-info "EXP-016 scene upload failed"
                          {:index index :value value})))))
    (when-not (= (count scene-commands)
                 (project-scene-commit (count scene-commands)))
      (throw (ex-info "EXP-016 scene commit failed" {})))))

(defn -main [& args]
  (upload-scene!)
  (apply witness/-main args)
  (println "EXP-016-JOLT-SCENE-COMMITTED"))
