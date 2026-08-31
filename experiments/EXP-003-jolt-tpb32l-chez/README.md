# EXP-003 — Native threaded portable-bytecode Chez audit

## Problem

Audit the closest native threaded Chez portable-bytecode target before Jolt
compatibility work.

## Hypothesis

Chez's documented `--threads --pbarch` configuration should build a threaded
portable-bytecode target in the locked Nix environment.

## Environment

Chez `7fadeee45fcc0135b17f5c1a926157004f898339` with submodules; Nix shell
compiler and libraries; Linux x86_64 host.

## Minimal reproduction

```sh
nix develop -c ./scripts/chez-tpb-build
printf '(display "EXP-003-TPB-OK\\n") (display (machine-type)) (newline) (display (+ 40 2)) (newline) (exit)\\n' \\
  | build/EXP-003-jolt-tpb32l/source/tpb64l/bin/tpb64l/scheme
```

## Expected

A threaded PB target builds and evaluates the arithmetic witness.

## Actual

**Observed 2026-08-31:** the locked Nix environment built the target and
printed:

```text
Chez Scheme Version 10.5.0-pre-release.1
EXP-003-TPB-OK
tpb64l
42
```

The `--threads --pbarch` options select `tpb64l` on this 64-bit host, not
`tpb32l`; the script name retains the planned experiment ID but does not claim
a 32-bit target. `--disable-x11 --disable-curses` was required because the
portable Nix shell intentionally does not provide desktop X11 headers.

## Investigation

This is an independent threaded Chez witness only. Jolt was not run against
this target: the current Jolt launcher is built for the host Chez machine and
there is no target-compatible Jolt boot payload yet. Therefore this does not
establish Jolt compatibility.

## Result

**Observed:** stock threaded `tpb64l` Chez builds and evaluates on the host.
**Reduced blocker:** the requested Jolt-on-native-tpb compatibility audit
remains unproven because the Jolt target boot/launcher has not been cross-minted.

## Suspected layer

`JOLT_CHEZ_HOST` / target boot integration, not the stock Chez threaded build.

## Workaround or next experiment

Cross-mint a Jolt boot payload for `tpb64l` before claiming Jolt compatibility;
do not silently substitute host `a6le` Jolt execution.

## Artifacts and hashes

- `artifacts/logs/EXP-003/build.log`
- ignored `build/EXP-003-jolt-tpb32l/source/tpb64l/`
