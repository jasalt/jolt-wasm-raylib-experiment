# EXP-015 — Jolt static Raylib facade

## Problem

EXP-014 proves threaded Jolt in Chromium but not Jolt-to-Raylib calls.

## Hypothesis

A signed-scalar `Sforeign_symbol` facade can let Jolt select an EXP-007 Raylib scene without importing desktop raylib-jlt bindings.

## Environment

Uses the pinned EXP-014 Jolt, Chez, Emscripten, and Raylib revisions.

## Minimal reproduction

Pending a dedicated build command.

## Expected

Jolt calls `project_set_scene`; C owns the browser frame loop and renders the selected scene.

## Actual

Not yet observed.

## Investigation

Only the EXP-006-proven signed `int32` ABI is in scope. Input and per-frame Jolt callbacks are separate experiments.

## Result

Proposed.

## Suspected layer

`JOLT_FFI` static symbol resolution.

## Workaround or next experiment

Link the exact EXP-007 facade into the EXP-014 libffi build and mint `app.exp015`.

## Upstream suitability

Project-local experiment; no upstream patch proposed.

## Artifacts and hashes

To be recorded after execution.
