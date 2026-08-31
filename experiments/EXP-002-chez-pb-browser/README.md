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

**Observed 2026-08-31:** the Emscripten page loaded over HTTP and requested
`scheme.js`, `scheme.data`, and `scheme.wasm` successfully. Chromium produced no
uncaught page exception in the captured output. However, the custom DOM marker
remained `loading` and the boot token was not emitted; only the Petite Chez
banner appeared. The script therefore exited nonzero at its readiness assertion.

## Investigation

The EXP-001 generated Node output executes its boot callback under Node. The
browser output has the runtime assets, but this reduced witness does not yet
prove that the custom `--emboot=witness.boot` callback is selected/executed in
the browser shell. The failure is retained rather than being called a pass.

## Result

**Reduced blocker — `CHEZ_EMSCRIPTEN` / `BROWSER_RENDERING`:** browser asset
loading works, but boot-payload completion is not yet demonstrated. This blocks
claiming W2 (Chez in a browser) and must be resolved before browser Raylib or
Jolt work.

## Workaround or next experiment

Compare the generated upstream `scheme.html` shell and its `Module` lifecycle
with the custom shell; inspect the exact `--emboot` preload naming and boot
selection. Do not infer success from the Petite banner or asset requests.

## Artifacts and hashes

- `artifacts/logs/EXP-002/browser.log`
- `artifacts/reports/EXP-002-browser.txt`
- ignored generated `build/EXP-002-chez-pb-browser/`
