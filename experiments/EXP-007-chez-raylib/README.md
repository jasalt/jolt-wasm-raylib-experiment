# EXP-007 — Chez static facade drives a Raylib browser frame

## Problem

Combine the proven pinned Chez Emscripten runtime, the plain Raylib web
baseline, and only the signed scalar static FFI shape proven by EXP-006.

## Reproduction

```sh
nix develop -c env SCENE=green ./experiments/EXP-007-chez-raylib/commands.sh
nix develop -c env SCENE=red ./experiments/EXP-007-chez-raylib/commands.sh
nix develop -c env SCENE=green ./experiments/EXP-007-chez-raylib/browser-smoke
nix develop -c env SCENE=red ./experiments/EXP-007-chez-raylib/browser-smoke
```

`project-raylib-init.patch` is applied to a copied pinned Chez worktree. The C
facade registers one `(integer-32) -> integer-32` symbol. Scheme selects scene
1 or 2 and returns promptly. C then initializes Raylib and installs
`project_draw_frame` with `emscripten_set_main_loop`; browser/C owns every
Raylib and frame-loop operation. No Scheme callback is retained and no worker
or native evaluator calls Raylib.

## Observed result (2026-08-31)

Both automated Chromium runs reached explicit readiness after their first
completed frame, with HTTP assets present and empty page-error and request-
failure arrays. The status text and Chez output identify the same scene. The
project C patch SHA-256 is
`fc6c97d1699edd15e694a58b29e233d1cf5a3e394120d0dc6e0a64addf7768c0`
for both builds. A source diff shows the Scheme files differ only in scene
literal, expected value, and diagnostic token; the C facade is unchanged.

Vision inspection of the full-page screenshots observed:

- green: a vivid green circle and rectangle, the legible title `Chez static
  facade + Raylib`, `Scheme scene: 1`, and Chez token `scene=1`;
- red: the same layout and C-rendered text with a vivid red circle and
  rectangle, `Scheme scene: 2`, and Chez token `scene=2`.

This is semantic browser-render evidence, not a build or process-survival
claim.

## Evidence

| scene | page SHA-256 | canvas SHA-256 |
| --- | --- | --- |
| green | `3bef03968a18c8128d453264f0610a14f5786ba83c7b63f9251bd6f31e3bcabc` | `ee89fd2242048d7b667232bfc9ffe5e945df7cf2b66d152d65c32a14e610b779` |
| red | `fd26b83af7708848c169f5cd8ef9a41f9aca12609c36bc01de5f34114e3cf9a9` | `5cc82d8e5369c41ab2071eee24549364ddef82ade3c05a98890ef35278072a14` |

Generated logs, JSON reports, screenshots, Wasm, JS, and data remain ignored.

## Result

**PASS — Chez-driven first frame (not Jolt-driven):** pinned Chez portable
bytecode selects visible state through the proven static signed-scalar facade,
and C/browser-owned Raylib renders it. This establishes the prerequisite for a
Jolt-generated boot payload but does not itself claim Jolt execution.
