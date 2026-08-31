# EXP-015 — Jolt static Raylib facade

## Problem

EXP-014 proves threaded Jolt in Chromium but not Jolt-to-Raylib calls.

## Hypothesis

A signed-scalar `Sforeign_symbol` facade can let Jolt select an EXP-007 Raylib scene without importing desktop raylib-jlt bindings.

## Environment

Uses the pinned EXP-014 Jolt, Chez, Emscripten, and Raylib revisions.

## Minimal reproduction

The first successful build used the EXP-014 libffi cross host plus a fresh
`tpb32l` target pack rebuilt from the identical Raylib-patched Chez tree. It
then minted `app.exp015`, configured Chez with `--emscripten --threads --pbarch
--enable-libffi`, linked the pinned Raylib web archive, and ran `browser-smoke`.

## Expected

Jolt calls `project_set_scene`; C owns the browser frame loop and renders the selected scene.

## Actual

**Observed:** `app.exp015` called `project_set_scene` through `jolt.ffi` before
C started its browser-owned Raylib loop. Chromium output contains both the
canonical Jolt lines and `EXP-015-JOLT-RAYLIB-SCENE-SELECTED`; the DOM readiness
marker identifies scene 1. The inspected screenshot visibly shows the dark
Raylib canvas, a bright green circle and rectangle, the facade label, scene 1,
and the Jolt output.

The initial build reused an older target pack and failed before application
entry with `cannot find compatible scheme.js.boot`. Rebuilding the target pack
from the exact Raylib-patched tree resolved that compatibility mismatch.

## Investigation

Only the EXP-006-proven signed `int32` ABI is in scope. Input and per-frame Jolt callbacks are separate experiments.

## Result

PASS for the narrow static-symbol boundary and browser input facade. Jolt
selects scalar input mode; the C-owned Raylib owner loop reads browser input.
Chromium automation moved the mouse and held ArrowRight. The inspected screenshot
shows mouse `467,115`, `key-right: 1`, a moved green circle, and the rectangle
shifted right. This is not a raylib-jlt port or per-frame Jolt execution.

## Suspected layer

Resolved `JOLT_FFI` static symbol resolution for signed `int32`.

## Workaround or next experiment

Adapt applicable scalar-only raylib-jlt demos only after defining a data/owner
boundary; C must not call drawing from an evaluator worker.

## Upstream suitability

Project-local experiment; no upstream patch proposed.

## Artifacts and hashes

- `patches/chez-raylib-input-facade.patch` — SHA-256
  `85ddbf655fd0eee7341e193f765b886f3b938f2171802eca7463e24ccd017fac`
- `artifacts/reports/EXP-015-static-browser.json` — SHA-256
  `be8233a0f3d86f48923a84a16fef78ce98326f2414af32298ddadd8078063e26`
- `artifacts/screenshots/EXP-014/exp015-jolt-raylib/page.png` (vision inspected),
  SHA-256 `2d852f6d3805626c4a11a826480ef601c34b4f344cb8ebc14a560a89b324cf2d`
- `artifacts/logs/EXP-014/exp015-{server,chromium,headers}.log`
