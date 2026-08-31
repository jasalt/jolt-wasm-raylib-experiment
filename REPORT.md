# Feasibility report — Jolt → Chez Wasm → Raylib

## Conclusion

**Highest demonstrated level: W3 — static FFI and plain Raylib.**

Pinned Chez portable bytecode runs under Node and Chromium (W1). Pinned Raylib
renders a vision-inspected browser scene, and Chez reaches a statically
registered C facade through independently measured portable-bytecode ABI shapes
(W3). A stronger integration control also proves that a Scheme-selected signed
scalar visibly changes a browser-owned Raylib frame while C owns scheduling.

**W2 and W4–W6 are not achieved.** The exact revision-matched Jolt compiler
emits its full Scheme payload, and that source recompiles into a genuine `pb`
boot. The boot then fails before application startup at Jolt's top-level
`make-mutex`. Pinned Chez has no threaded `tpb` Emscripten boot, while Jolt's
own threadless-adapter specification says degraded browser semantics are design
only and not implemented. Consequently no Jolt browser fixture, Jolt-driven
frame, persistent Jolt state, or browser live redefinition is claimed.

## Pinned boundary

| component | revision/tool |
| --- | --- |
| Jolt | `447b874d06066d15fee187200fabaf410f4ff5b6` |
| Chez Scheme | `7fadeee45fcc0135b17f5c1a926157004f898339` |
| Raylib | `9f3cadf1e618f125bd9b282c7759f8cb26ce17fc` |
| Raylib-Jolt reference | `7685ed987aa2dc27ab2499f2804bb28b793d6638` |
| Emscripten | locked Nix shell, observed `6.0.8-git` |
| browser evidence | headless Chromium `152.0.7977.64`, SwiftShader |

## Evidence ladder

| experiment | result | evidence boundary |
| --- | --- | --- |
| EXP-000 native pure Jolt | PASS | native model/tooling only |
| EXP-001 stock Chez `pb` Node | PASS | Chez/Wasm Node, no Jolt |
| EXP-002 stock Chez `pb` Chromium | PASS | explicit DOM ready, clean diagnostics, vision-inspected payload execution |
| EXP-003 native `tpb64l` | PASS | threaded native PB, not Emscripten |
| EXP-004 exact-host Jolt emission | PARTIAL | Jolt emits/compiles `flat.ss`; native link configuration fails later |
| EXP-005 plain Raylib Chromium | PASS | browser-owned frame, clean diagnostics, vision inspection |
| EXP-006 static FFI | PARTIAL PASS | no-arg and signed-32 pass; unsigned/pointer/string/memory shapes fail clearly |
| EXP-007 Chez + static facade + Raylib | PASS | Scheme scenes 1/2 visibly produce green/red frames; not Jolt |
| EXP-008 pure Jolt browser payload | FAIL | genuine `pb` boot aborts at `make-mutex` before app startup |
| EXP-009/010 Jolt declarations/frame | SKIP | no initialized Jolt browser runtime |
| EXP-011/012 lifecycle/input | SKIP | no Jolt first frame or persistent model |
| EXP-013 live redefinition | SKIP | no persistent Jolt browser instance; no eval bridge added |

Detailed commands, exact errors, screenshot hashes, and semantic observations
are in each `experiments/EXP-NNN-*/README.md`. Generated logs and screenshots
remain ignored by design.

## Visual evidence inspected

EXP-005's full-page screenshot visibly showed the dark-blue diagnostic canvas,
green circle, blue and yellow rectangles, and legible Raylib/frame text.

EXP-007's two full-page screenshots were inspected in this session. They show
the same dark diagnostic layout, legible `Chez static facade + Raylib` text,
and matching Chez tokens. Scene 1 has a vivid green circle and rectangle;
scene 2 has the same shapes in vivid red. The facade patch is byte-identical
between builds; the Scheme witness changes only the scene literal/expectation
and token. This proves visible Scheme control without implying Jolt execution.

## Size observation

The observed EXP-007 green integration output is:

- `scheme.js`: 231,649 bytes;
- `scheme.wasm`: 850,371 bytes; and
- `scheme.data`: 2,063,571 bytes.

These are uncompressed `-O2`/Raylib integration artifacts from the locked shell,
not download-size or performance claims. Startup percentiles, memory, 10-minute
rendering, and 10,000 Jolt updates are skipped because the prerequisite Jolt
browser runtime does not initialize; reporting those on the Chez-only control
would answer a different question.

## Architecture and ownership demonstrated

```d2
Jolt-emitted Scheme -> "pb boot creation: succeeds"
"pb boot creation: succeeds" -> "Jolt runtime make-mutex: FAIL"

"Scheme EXP-007" -> "signed int32 static facade": "scene id; returns"
"signed int32 static facade" -> "C/browser owner"
"C/browser owner" -> "requestAnimationFrame"
"C/browser owner" -> "Raylib PLATFORM_WEB"
"Raylib PLATFORM_WEB" -> "HTML canvas"
```

C/browser owns Raylib initialization, drawing, and the Emscripten callback.
Scheme sets one scalar and returns. No Scheme callback or Scheme object is held
by C, no evaluator worker calls Raylib, and no browser `dlopen` or libffi is
used.

## Limitations and required upstream work

1. Implement Jolt's documented threadless adapter semantics (or supply and
   validate a compatible threaded Emscripten Chez target) before rerunning
   EXP-008.
2. Re-establish native/Node/browser canonical fixture parity only after that
   boot reaches `app.witness`.
3. Expand the C facade solely through measured supported prototypes; EXP-006
   shows unsigned and pointer-shaped assumptions are unsafe in this target.
4. Only then execute the Jolt first-frame, 600-frame/input, stress, and
   debug-redefinition gates.

The experiment therefore proves that the Chez/Wasm + static facade + Raylib
substrate is feasible, but **does not prove Jolt on that browser substrate**.
