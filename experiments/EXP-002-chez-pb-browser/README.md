# EXP-002 — Chez portable bytecode browser witness

## Problem

Run the EXP-001 stock Chez `pb` Emscripten output in a real browser and expose
completion in the DOM.

## Hypothesis

The same `pb --emscripten --empetite --emboot` output that runs under Node will
execute its boot callback when loaded over HTTP in Chromium.

## Environment

Chez `7fadeee45fcc0135b17f5c1a926157004f898339`; Emscripten `6.0.8-git`;
Chromium 152 from the Nix shell; loopback Python HTTP server.

## Minimal reproduction

```sh
rm -rf build/EXP-001-chez-pb-node build/EXP-002-chez-pb-browser
nix develop -c ./scripts/chez-browser-smoke
```

## Expected

The generated `scheme.js` loads `scheme.data`/`scheme.wasm`, invokes the boot
payload, and the DOM changes to `data-chez-state="ready"` with the token
`EXP-002-PB-BROWSER-OK`.

## Actual

**Original observation, preserved:** the first browser run requested
`scheme.js`, `scheme.data`, and `scheme.wasm` successfully and printed the
Petite banner plus `EXP-001-PB-OK`, `pb`, `42`, and `3.75`. The DOM remained
`loading` only because the shell expected `EXP-002-PB-BROWSER-OK`.

**Remediation observation, 2026-08-31:** a clean Nix-controlled build embedded
the EXP-002 witness. Chromium 152.0.7977.64 received HTTP 200 for `scheme.js`,
`scheme.data`, and `scheme.wasm`; the intended token, machine type `pb`, and
value `42` appeared; `data-chez-state` became `ready`; and the DevTools capture
reported no console message, page exception, or request failure.

Commands, run from the repository root:

```sh
rm -rf build/EXP-001-chez-pb-node build/EXP-002-chez-pb-browser
nix develop -c ./scripts/chez-browser-smoke
# After correcting an automation-only failure classification, reuse the exact
# clean-built module rather than rebuilding it:
nix develop -c env CHEZ_REBUILD=0 ./scripts/chez-browser-smoke
```

## Investigation

The earlier diagnosis was incorrect: custom boot-payload execution **was
observed**, but build/token wiring was mismatched. `scripts/chez-wasm-build`
always copied the EXP-001 witness while the EXP-002 shell intentionally waited
for the EXP-002 token. The browser witness also now installs `scheme-start` and
exits, avoiding a blocked browser main thread after completion. The build driver
selects the EXP-002 source explicitly and keeps its generated tree separate.

## Result

**PASS — `CHEZ_EMSCRIPTEN` / `BROWSER_RENDERING`:** the pinned Chez `pb`
portable-bytecode payload executes in a real loopback-served browser and exposes
explicit DOM readiness. This remediates the EXP-002 evidence boundary; it does
not by itself establish Jolt or Raylib browser execution.

## Visual observation

The inspected full-page screenshot visibly shows the heading “Chez portable
bytecode browser witness”, status “ready”, Petite Chez Scheme
10.5.0-pre-release.1, token `EXP-002-PB-BROWSER-OK`, machine type `pb`, and value
`42`. Text is legible and no browser error surface is visible.

## Artifacts and hashes

- `artifacts/logs/EXP-002/build.log`
- `artifacts/logs/EXP-002/build-driver.log`
- `artifacts/logs/EXP-002/server.log`
- `artifacts/logs/EXP-002/chromium.log`
- `artifacts/reports/EXP-002-browser.json`
- `artifacts/screenshots/EXP-002/page.png` — SHA-256
  `e1cf498dc9ee22381ce6de4d17bf797b1b11e0745aacd45e1f803d644cee0b21`
- ignored generated `build/EXP-002-chez-pb-browser/`
