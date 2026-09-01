# EXP-016 — Jolt-defined interactive Raylib scene

## Problem

EXP-015 proves that Jolt can select a C-authored Raylib scene, but its geometry,
colors, and input behavior are hard-coded in C. It does not prove that Jolt can
define the scene while preserving the proven browser/Raylib owner boundary.

## Hypothesis

Jolt can define a compact command scene and upload every signed scalar through
the EXP-006-proven ABI before the browser frame loop starts. A generic C host
can then interpret those commands on the Raylib owner thread without containing
scene-specific geometry or colors.

## Environment

This experiment reuses the exact pinned Jolt, Chez, Emscripten, libffi, and
Raylib revisions and patched threaded `tpb32l` source lineage from EXP-014 and
EXP-015. The successful browser was Chrome/Chromium 152.0.7977.64.

## Minimal reproduction

`src/app/exp016.clj` defines four ten-field commands:

1. dark background;
2. inset panel rectangle;
3. red circle whose x/y come from Raylib mouse input; and
4. red rectangle whose x gains 100 while ArrowRight is down.

Jolt uploads each scalar with `project_scene_write(index, value)` and commits the
command count with `project_scene_commit(count)`. The patch in `patches/`
replaces EXP-015's scene-specific C with a bounded generic command buffer and
renderer. `commands.sh` mints the Jolt boot, links the browser module, and runs
the Chromium gate.

## Expected

The same visual composition and input behavior as EXP-015 appears, but the
shape types, positions, dimensions, colors, and input mapping originate in the
Jolt `scene-commands` value rather than C literals.

## Actual

**PASS.** Chromium reached `EXP-016-JOLT-SCENE-COMMITTED` with
`crossOriginIsolated` and `SharedArrayBuffer`, no page exception, and four
committed commands. Automation moved the mouse to page coordinate 500,250 and
held ArrowRight while capturing.

Vision inspection of `artifacts/screenshots/EXP-016/page.png` shows:

- `ready: Jolt scene (4 commands)`;
- the same dark background and inset panel;
- a red circle at reported canvas mouse coordinate `467,115`;
- a red rectangle shifted right while `key-right: 1`;
- `Jolt command scene + Raylib`; and
- canonical Jolt output plus `EXP-016-JOLT-SCENE-COMMITTED` below the canvas.

## Investigation

The C host still polls input and invokes Raylib because those operations must
remain on the proven frame owner. “Defined in Jolt” means Jolt owns the complete
data-oriented scene description; it does not mean re-entering Jolt from every
browser callback. The C renderer contains only bounded command decoding,
Raylib calls, readiness, and scheduling.

The command fields are:

```text
op x y width-or-radius height red green blue input-x input-y
```

Operations are background (`1`), rectangle (`2`), and circle (`3`). Input mode
`1` substitutes the corresponding mouse coordinate; mode `2` adds 100 while
ArrowRight is held.

## Result

PASS for a Jolt-defined interactive scene over the signed-scalar command ABI.
This is stronger than EXP-015 scene selection, but it is not arbitrary direct
Raylib FFI from per-frame Jolt code.

## Suspected layer

No unresolved failure. The retained boundary is architectural: C/Raylib owns
the frame and browser input; Jolt owns scene data.

## Workaround or next experiment

A later experiment could double-buffer commands for bounded owner-thread scene
updates or add text commands. It must prove atomic commit semantics before
updating a live command buffer.

## Upstream suitability

The command ABI is project-local evidence. Its data-oriented shape may inform a
future `raylib-jlt` Wasm platform layer, but no upstream API is proposed yet.

## Artifacts and hashes

- `src/app/exp016.clj` — SHA-256
  `36556722795da5307d81de13de3f84e7356a03b8f45f183dbc7f11cbd56a430c`
- `patches/jolt-command-scene.patch` — SHA-256
  `731d2707070640825bcffa8ee97b3fd8362b4c5d202009d4084b8d26255a753b`
- `artifacts/reports/EXP-016-browser.json` — SHA-256
  `c6d0ac27ca63ba90a48bd479c1332dd91f6edc68a982a7837ab205b2cc09fd50`
- `artifacts/screenshots/EXP-016/page.png` — SHA-256
  `ee585aab22e0b91298509e42ce086bf75ad4da011ab9359d578c11669f74af29`
