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

**Planning and task decomposition only.** No Jolt/Wasm or Jolt/Raylib browser
rendering claim has been demonstrated in this repository yet.

The research proceeds in small proofs: stock Chez under Node and a browser,
Jolt without graphics, plain C Raylib in a browser, static Chez-to-C FFI, one
Chez-driven frame, and finally one Jolt-driven persistent frame loop. Browser
rendering is validated with browser automation, screenshots, and semantic
inspection by a vision-capable coding agent.

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
- [Raylib](https://github.com/raysan5/raylib)
- [`../jolt-android`](../jolt-android) — experiment documentation and evidence
  conventions followed by this project

Live task state is tracked in [Beads task tracker (read only)](https://jasalt.github.io/jolt-wasm-raylib-experiment/bv/); the plan remains a research specification.
