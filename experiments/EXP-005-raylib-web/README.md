# EXP-005 — Plain C Raylib `PLATFORM_WEB` baseline

## Problem

Prove that pinned Raylib renders a diagnostic scene in a real browser before
combining it with Chez or Jolt.

## Hypothesis

The pinned Raylib sources can be compiled by pinned Emscripten for
`PLATFORM_WEB`; a browser-owned Emscripten frame callback can draw a stable,
recognizable canvas scene.

## Environment

- Raylib: `9f3cadf1e618f125bd9b282c7759f8cb26ce17fc` from `pins.edn`.
- Emscripten: `6.0.8-git`, from the locked Nix shell.
- Browser: locked-shell Chromium, DevTools-protocol automation, headless with
  SwiftShader.
- Server: `scripts/web-serve`, loopback-only, no-cache, Wasm MIME type, and
  COOP/COEP response headers.

## Minimal reproduction

```sh
nix develop -c ./scripts/browser-smoke
```

The script rebuilds the Raylib archive, serves it over loopback HTTP, launches a
real Chromium browser, observes readiness, collects console/page/request
failures, captures page and canvas PNGs, and writes a JSON report.

## Expected

The browser reports the DOM readiness state, a 720×360 Raylib canvas is
nonblank, and the scene visibly contains the dark-blue field, green circle,
blue rectangle, yellow rectangle, and legible Raylib/frame text. No page errors
or failed requests are accepted.

## Actual

**Observed 2026-08-31:** `nix develop -c ./scripts/browser-smoke` exited 0.
The browser report records readiness, no page errors, no failed requests, and
nonzero canvas dimensions. Raylib logged `PLATFORM: WEB: Initialized
successfully` and reported a Chromium WebGL 1 renderer.

A vision inspection of `page.png` found the expected dark page, a titled
`Raylib PLATFORM_WEB diagnostic` status surface, dark-blue diagnostic canvas,
bright green circle, blue rectangle, yellow rectangle, and legible in-canvas
`Raylib PLATFORM_WEB` plus frame text. This is an observed browser render, not merely a
built Wasm module.

## Investigation

The witness deliberately uses `emscripten_set_main_loop` rather than a blocking
`while (!WindowShouldClose())` loop. It compiles Raylib modules from the pinned
source directly with `PLATFORM_WEB` and `GRAPHICS_API_OPENGL_ES2`; no Chez,
Jolt, custom FFI, assets, or Asyncify are involved.

## Result

**Observed — `RAYLIB_WEB`:** the plain C Raylib browser baseline works under
the locked tool boundary. This establishes neither Chez/Wasm nor Jolt/Raylib
integration.

## Suspected layer

Not applicable; the focused baseline succeeded.

## Workaround or next experiment

EXP-007 may use this browser-owned frame-loop and diagnostic-validation pattern
only after its Chez FFI prerequisites are independently proved.

## Upstream suitability

No patch or workaround was required. Raylib compilation emitted two upstream
`-Wall` warnings (`rshapes.c` unused set variable and `stb_vorbis.c` pointer
comparison); both are retained in the ignored build log and did not prevent the
browser witness.

## Artifacts and hashes

- `artifacts/logs/EXP-005/build.log`
- `artifacts/logs/EXP-005/server.log`
- `artifacts/logs/EXP-005/chromium.log`
- `artifacts/reports/EXP-005-browser.json`
- `artifacts/screenshots/EXP-005/page.png`
  `433e2f3f1b40895958862c62b8ff1e06e9fbc578e66035c106473c3ac80577bf`
- `artifacts/screenshots/EXP-005/canvas.png`
  `5050c20372155128a5112112b02c31a0c4ba43c2223ad95164cf4c58d011e308`

Generated artifacts remain ignored; hashes and the visual observation above
identify the retained evidence.
