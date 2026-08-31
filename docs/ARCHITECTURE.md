# Demonstrated architecture

The highest demonstrated path is Chez Scheme, not Jolt:

```d2
"Scheme boot" -> "project_set_scene(int32)"
"project_set_scene(int32)" -> "C-owned scene state"
"C-owned scene state" -> "browser requestAnimationFrame"
"browser requestAnimationFrame" -> "Raylib PLATFORM_WEB"
"Raylib PLATFORM_WEB" -> "HTML canvas"
```

The Scheme boot calls one statically registered `(integer-32) -> integer-32`
facade function and returns. C/browser then owns Raylib initialization, frame
scheduling, drawing, readiness publication, and the scalar scene state. C does
not retain a Scheme callback or Scheme object. This owner arrangement is proven
by EXP-007's two automated, vision-inspected Chromium scenes.

The intended Jolt edge is blocked before application startup:

```d2
"Jolt-emitted flat.ss" -> "pinned pb compiler": "PASS"
"pinned pb compiler" -> "genuine Jolt pb boot": "PASS"
"genuine Jolt pb boot" -> "top-level make-mutex": "FAIL"
"top-level make-mutex" -> "application startup": "not reached"
```

Pinned Chez's Emscripten path supplies non-threaded `pb`; pinned Jolt requires
thread primitives during runtime initialization and documents its threadless
adapter as not implemented. See EXP-008 and `REPORT.md`.
