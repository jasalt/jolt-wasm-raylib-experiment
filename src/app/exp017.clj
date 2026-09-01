(ns app.exp017
  "Wasm adaptation of raylib-jlt's Flappy Bird example. Jolt owns the model,
  physics, collision, scoring, pipe recycling, and drawing command generation."
  (:require [jolt.ffi :as ffi]
            [app.witness :as witness]))

(declare project-scene-write project-scene-commit project-flap-pressed)
(ffi/defcfn project-scene-write "project_scene_write" [:int32 :int32] :int32)
(ffi/defcfn project-scene-commit "project_scene_commit" [:int32] :int32)
(ffi/defcfn project-flap-pressed "project_flap_pressed" [] :int32)

(def width 800)
(def height 450)
(def bird-x 150)
(def bird-r 14)
;; Keep tenths so the proven signed-int32 ABI carries deterministic physics.
(def gravity10 4)
(def flap10 -70)
(def pipe-w 70)
(def gap-h 140)
(def scroll 3)
(def spacing 300)

(defonce seed (atom 1701))

(defn- rand-gap []
  (let [next-seed (mod (+ (* @seed 1103515245) 12345) 2147483647)]
    (reset! seed next-seed)
    (+ 80 (mod next-seed (- height 160 gap-h)))))

(defn- new-game []
  {:y10 2250
   :vy10 0
   :score 0
   :over? false
   :pipes (mapv (fn [i] {:x (+ 500 (* i spacing))
                         :gap (rand-gap)
                         :scored false})
                (range 3))})

(defonce game (atom (new-game)))

(defn- step [{:keys [y10 vy10 pipes score] :as st} flap?]
  (let [vy10 (if flap? flap10 (+ vy10 gravity10))
        ny10 (+ y10 vy10)
        ny (quot ny10 10)
        pipes (mapv (fn [p]
                      (let [nx (- (:x p) scroll)]
                        (if (< nx (- pipe-w))
                          {:x (+ nx (* 3 spacing))
                           :gap (rand-gap)
                           :scored false}
                          (assoc p :x nx))))
                    pipes)
        passed (count (filter (fn [p]
                                (and (not (:scored p))
                                     (< (+ (:x p) pipe-w) bird-x)))
                              pipes))
        pipes (mapv (fn [p]
                      (if (and (not (:scored p))
                               (< (+ (:x p) pipe-w) bird-x))
                        (assoc p :scored true)
                        p))
                    pipes)
        hit-pipe? (some (fn [p]
                          (and (< (- bird-x bird-r) (+ (:x p) pipe-w))
                               (> (+ bird-x bird-r) (:x p))
                               (or (< (- ny bird-r) (:gap p))
                                   (> (+ ny bird-r) (+ (:gap p) gap-h)))))
                        pipes)
        oob? (or (< (- ny bird-r) 0)
                 (> (+ ny bird-r) height))]
    (if (or hit-pipe? oob?)
      (assoc st :over? true :y10 ny10 :vy10 vy10)
      (assoc st :y10 ny10 :vy10 vy10 :pipes pipes
             :score (+ score passed)))))

(defn- command [op x y w h red green blue]
  [op x y w h red green blue 0 0])

(defn- scene-commands [{:keys [y10 pipes score over?]}]
  (vec
   (concat
    [(command 1 0 0 0 0 102 191 255)]
    (mapcat (fn [{:keys [x gap]}]
              [(command 2 x 0 pipe-w gap 0 117 44)
               (command 2 x (+ gap gap-h) pipe-w
                        (- height (+ gap gap-h)) 0 117 44)])
            pipes)
    [(command 3 bird-x (quot y10 10) bird-r 0 255 203 0)
     (command 4 score 8 0 0 0 82 172)]
    (when over? [(command 5 0 0 0 0 190 33 55)]))))

(defn- upload-scene! [commands]
  (let [values (vec (apply concat commands))]
    (doseq [index (range (count values))]
      (project-scene-write index (nth values index)))
    (project-scene-commit (count commands))))

(defn frame! []
  (let [flap? (= 1 (project-flap-pressed))
        st (if (:over? @game)
             (if flap? (new-game) @game)
             (step @game flap?))]
    (reset! game st)
    (upload-scene! (scene-commands st))))

(defn -main [& args]
  (upload-scene! (scene-commands @game))
  (apply witness/-main args)
  (println "EXP-017-JOLT-FLAPPY-READY"))
