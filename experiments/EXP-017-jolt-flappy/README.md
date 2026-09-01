# EXP-017 — raylib-jlt Flappy Bird with Jolt-owned gameplay

## Problem

EXP-016 proves a Jolt-authored static command scene. The requested next step is
to preserve as much as possible of `raylib-jlt`'s `flappy_bird.clj`, including
its persistent game state and per-frame Clojure update, rather than moving game
logic into C/Raylib.

## Hypothesis

The browser owner can call one named Scheme wrapper each frame; that wrapper can
dynamically resolve Jolt's `frame!` Var. Jolt can retain the Flappy Bird model,
physics, collision, scoring, pipe recycling, restart behavior, and scene command
generation. C can remain a generic bounded renderer and input primitive.

## Environment

Pinned EXP-014/016 Jolt, Chez `tpb32l`, Emscripten, libffi, and Raylib lineage.
Source reference: local `../raylib-jlt` commit
`1ba04380f48870441ff8eb46b3c25e36764b65a1`, file
`src/net/b12n/raylib_jlt/flappy_bird.clj`. Browser: Chromium 152.0.7977.64.

## Minimal reproduction

`src/app/exp017.clj` retains the source example's constants, `new-game`, `step`,
pipe transforms, pass scoring, AABB/circle collision, out-of-bounds handling,
game-over/restart flow, and shape generation. `defonce game` retains model state.
Each owner-thread callback calls the live `frame!` Var, which updates the model
and uploads a fresh generic command list.

Run `commands.sh` after the exact EXP-014/016 prerequisite build tree exists.
It appends the small named Scheme callback to Jolt's emitted flat Scheme,
remints the boot, links Raylib, and runs `browser-smoke`.

## Expected

A recognizable Flappy Bird scene continuously updates from Jolt state. Space
and left click both flap. Browser evidence has no page exception and records
that both input edges reached Jolt through the generic input primitive.

## Actual

**PASS.** The final browser report records 39 Jolt-driven frames and two
consumed flaps: one Space and one left click. It records cross-origin isolation,
`SharedArrayBuffer`, `EXP-017-JOLT-FLAPPY-READY`, no page errors, and no
actionable request failure.

Vision inspection of `artifacts/screenshots/EXP-017/page.png` shows:

- `ready: Jolt Flappy Bird (9 commands, 2 flaps)`;
- a sky-blue 800×450 game field;
- three scrolling pairs of dark-green pipes with gaps;
- a gold bird visibly raised after input;
- `score 0`; and
- canonical Jolt output plus `EXP-017-JOLT-FLAPPY-READY`.

## Investigation

### Preserved from raylib-jlt

- constants and overall namespace structure;
- map/vector model shape;
- gravity and flap update;
- three scrolling/recycling pipes;
- scored flags and pass counting;
- circle-versus-pipe and bounds collision;
- game-over and Space restart semantics; and
- scene generation from the Jolt model.

### Evidence-backed divergences

- Floating physics uses integer tenths because only signed `int32` is proven.
- Gap randomness uses a deterministic Jolt LCG rather than Raylib random FFI.
- Direct `rl/*` drawing becomes generic scalar commands interpreted by C.
- The browser frame owner calls Jolt `frame!`; Jolt does not own a blocking loop.
- Left click is added as a browser-friendly flap equivalent.
- C renders fixed score/game-over strings because UTF-8 command transport is not
  proven; Jolt still decides score value and whether the game-over command exists.

C contains no pipe locations, gaps, bird physics, score, collision, or game-over
rules. Its responsibilities are bounded command decoding, Raylib API calls,
Space/click edge polling, readiness diagnostics, and browser scheduling.

## Result

PASS for a recognizable and interactive Jolt-owned Flappy Bird adaptation with
per-frame Jolt model execution on the proven owner thread.

## Suspected layer

No unresolved failure. Remaining differences follow the proven signed-scalar
ABI and browser frame-ownership contract.

## Workaround or next experiment

Prove a bounded UTF-8/text command and atomic double-buffered command commits,
then remove the last fixed display strings from C.

## Upstream suitability

This is evidence for a data-oriented `raylib-jlt` Wasm platform layer. The
callback and command ABI remain experimental and should not be upstreamed before
lifetime, error propagation, and update-cost stress tests.

## Artifacts and hashes

- `src/app/exp017.clj` — SHA-256
  `1fabd311912b8a3a6c981327f0565db95c595e83a0ea1b4b8ebe4bdd7b75df81`
- `patches/jolt-frame-host.patch` — SHA-256
  `0a28ba07c1c3e46b9370973cd67034fd45e358e1a1951e0e5cd39a73bcca938d`
- `artifacts/reports/EXP-017-browser.json` — SHA-256
  `9ab005d89af82b05f4c4cc6ea52c1b96a21e7387f43c9127fc43684de4027ae0`
- `artifacts/screenshots/EXP-017/page.png` — SHA-256
  `2a385112610872a8f47fb0881a263f56a810e77d9779ae49933c5132f15bf15a`
