# Jolt + Chez Wasm + Raylib experiment

An evidence-driven experiment to determine whether a
[Jolt](https://jolt-lang.net/) application can run through
[Chez Scheme](https://cisco.github.io/ChezScheme/)'s Emscripten
portable-bytecode target and render with [Raylib](https://www.raylib.com/) in a
web browser.

The intended path is Jolt source → Jolt-emitted Scheme → a Chez `pb`-family boot
payload → Chez's portable-bytecode interpreter compiled to WebAssembly → a
statically registered C facade → Raylib `PLATFORM_WEB` → an HTML canvas. This is
not the existing Jolt Gambit-to-JavaScript backend, ClojureScript, or a JVM
runtime.

## Status

**Completed evidence ladder: W3.** Pinned Chez portable bytecode runs under
Node and Chromium; pinned Raylib renders in Chromium; and Chez reaches a
statically registered signed-scalar C facade. A two-scene integration witness
visibly proves Scheme-selected green/red Raylib frames under browser/C frame
ownership.

Jolt itself now runs on the distinct threaded Chez `tpb32l` browser target:
EXP-014 proves canonical Jolt output under Node and Chromium, including a
named Petite variant. The retained non-threaded `pb` control still aborts at
`make-mutex`; it is not representative of the threaded route. Raylib and input
integration remain downstream. See [REPORT.md](REPORT.md) and EXP-014.

Read the complete [PLAN.md](PLAN.md) for architecture, proof order, experiment
format, acceptance criteria, and graded outcomes. Coding agents must also read
[AGENTS.md](AGENTS.md).

## Development approach

```text
hypothesis
→ smallest reproducible experiment
→ native Jolt nREPL where possible
→ automate the successful observation
→ browser automation and screenshot inspection for visual claims
→ preserve evidence
→ atomic commit and push
```

The development-quality goal includes a debug-only, owner-thread-safe evaluation
path that visibly redefines a Var-backed function in a running browser module.
A normal native Jolt nREPL remains the primary fast loop for portable code.

## Related projects

- [Jolt](https://github.com/jolt-lang/jolt) — local sibling `../jolt`
- [Raylib-Jolt](https://github.com/jlt-commons/raylib-jlt) — local sibling
  `../raylib-jlt`; binding and REPL-pattern reference, not WebAssembly proof
- [Chez Scheme](https://github.com/cisco/ChezScheme)
- [racket-wasm-backend](https://github.com/bradlord/racket-wasm-backend/tree/411393882a1e9d726edc5dbc230b24f96d335398) —
  strong reference for threaded `tpb32l`: it cross-builds libffi 3.5.2, exposes
  static symbols through Chez, and runs Racket CS in an isolated browser worker.
  Its Chez patches apply cleanly to this project's pin and are a concrete lead
  for the current no-libffi blocker, but it is not Jolt/Raylib proof: it uses
  `PROXY_TO_PTHREAD` and disables Racket places after foreign calls in additional
  workers trapped.
- [Raylib](https://github.com/raysan5/raylib)
- [`../jolt-android`](../jolt-android) — experiment documentation and evidence
  conventions followed by this project

Live task state is tracked in [Beads task tracker (read only)](https://jasalt.github.io/jolt-wasm-raylib-experiment/bv/); the plan remains a research specification.
