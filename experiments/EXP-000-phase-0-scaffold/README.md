# EXP-000 — Phase 0 native Jolt scaffold witness

## Problem

Establish a pinned project boundary and a minimal native Jolt feedback witness.

## Hypothesis

The pinned Jolt source can load project source and execute a pure test.

## Environment

Recorded by `scripts/bootstrap` in `artifacts/reports/environment.txt`.

## Minimal reproduction

Run `./experiments/EXP-000-phase-0-scaffold/commands.sh` from the repository root.

## Expected

The native test prints `native Jolt witness: PASS`; an nREPL accepts a loopback
connection and emits its listening line.

## Actual

**Observed 2026-08-31 on `lima-default`:**

- `nix develop -c ./scripts/bootstrap` exited 0 and wrote the environment
  report from the locked shell.
- `nix develop -c ./scripts/test-native` exited 0. The flake-built pinned Jolt
  ran one test with one assertion and printed `native Jolt witness: PASS`.
- `nix develop -c ./scripts/nrepl-smoke` exited 0. It started the pinned Jolt
  nREPL server on TCP `127.0.0.1:7888`, made a loopback TCP connection, printed
  `loopback nREPL TCP connection: PASS`, then terminated the test server.

Raw command output is retained in ignored `artifacts/logs/EXP-000/`.

## Investigation

Phase 0 only; no Wasm, Raylib, browser, or FFI claim is made.

## Result

**Observed:** the native Jolt source witness and loopback nREPL prerequisite
work on this host. This does not establish a Nix-shell, Chez/Emscripten,
Raylib, FFI, or browser result.

## Suspected layer

Not applicable.

## Workaround or next experiment

Proceed to EXP-001 only after this scaffold is validated.

## Upstream suitability

No upstream patch or workaround.

## Artifacts and hashes

- `artifacts/logs/EXP-000/test-native.log`
- `artifacts/logs/EXP-000/nrepl-smoke.log`

These generated logs are intentionally ignored; their commands and result are
recorded above.
