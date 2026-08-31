# EXP-014 — Threaded Jolt on Chez `tpb32l` Emscripten

## Problem

EXP-008 established that the exact pinned Jolt application boot reaches its
first top-level `make-mutex` on the non-threaded Chez `pb` target and aborts
before application startup. The pinned Chez source documents a threaded
portable-bytecode Emscripten target family. EXP-014 tests that distinct target
route without changing Jolt's thread semantics.

## Hypothesis

Pinned Chez can generate a `tpb32l` boot target, run a real threaded witness,
and eventually execute the unchanged Jolt payload with Emscripten pthreads.
No result is inferred from the already-proven native `tpb64l` control.

## Environment

- Jolt: `447b874d06066d15fee187200fabaf410f4ff5b6`
- Chez: `7fadeee45fcc0135b17f5c1a926157004f898339`
- Emscripten: Nix shell; observed `6.0.8-git`
- Node: Nix shell; observed `v24.19.0`
- Chromium: Nix shell; observed `152.0.7977.64`

The full proposed procedure and gate definitions are in
[`../../EXP-014-jolt-tpb32l-emscripten/PLAN.md`](../../EXP-014-jolt-tpb32l-emscripten/PLAN.md).

## Minimal reproduction

```sh
nix develop -c ./experiments/EXP-014-jolt-tpb32l-emscripten/commands.sh control
```

The command records the current Nix-shell environment and reruns the narrow
non-threaded `pb` Jolt control. Later named modes are deliberately gated by
prior Beads work packages; they do not claim that a threaded target exists.

## Expected

The control must retain the historical condition: a genuine Jolt boot reaches
Jolt startup on `pb` and fails at `make-mutex`. A later `tpb32l` result may be
compared against this only after target generation and an independent Chez
thread witness pass.

## Actual

**Observed 2026-08-31:** `commands.sh control` reran the genuine EXP-008
control. It compiled the Jolt-emitted `flat.ss`, then aborted at:

```text
Call error: (1 0 #{make-mutex *top*:make-mutex} ())
exit_status=134
```

The control is not a Jolt browser success. It preserves the existing
`JOLT_THREADLESS_ADAPTER` boundary for non-threaded `pb`.

## Investigation

The root PLAN and pinned Chez `BUILDING` identify `make bootquick XM=tpb32l`
as the provisional stock cross-boot mechanism. Work package B must inspect and
run that mechanism against the exact Nix-pinned Chez source before any Jolt
payload is minted. `witness-thread.ss` is intentionally a non-executable
contract placeholder until that target exists; task C owns its API-correct
implementation and native execution.

## Result

**Control PASS / target status not yet run.** The current workspace remains at
the known non-threaded Jolt boundary. T0 through T6 are not established by this
scaffold or control.

| Gate | Result | Evidence |
| --- | --- | --- |
| T0 generated `tpb32l` boots | not run | — |
| T1 native thread witness | not run | — |
| T2 Emscripten Chez / Node | not run | — |
| T3 Jolt / Node | not run | — |
| T4 Chez / Chromium | not run | — |
| T5 Jolt / Chromium | not run | — |
| T6 Petite Jolt / Chromium | not run | — |

## Suspected layer

The retained control is `JOLT_THREADLESS_ADAPTER` on `pb`. It does not classify
the untested `tpb32l` route.

## Workaround or next experiment

Proceed to T0 only: generate target boots from the stock pinned Chez source.
Do not patch Jolt, add `PROXY_TO_PTHREAD`, substitute a host Scheme, or mix in
Raylib/FFI work.

## Upstream suitability

No upstream patch is proposed. See [`patches/README.md`](patches/README.md) for
the no-patch discipline.

## Artifacts and hashes

Ignored reproducibility logs created by `control`:

- `artifacts/logs/EXP-014/bootstrap.log` — SHA-256
  `e5009ccd95940239f7d5ac93188d54c2613a4854bb93a5900aeb64733f6a7396`
- `artifacts/logs/EXP-014/pb-control.log` — SHA-256
  `2b13fce449e33bd0440070d46ff0137805c38fc4eb65a6136b2c2363f0bf67a6`
- Existing immutable EXP-008 evidence:
  `artifacts/logs/EXP-008-native-pb.log` — SHA-256
  `dcbb6a2ab1ccb7e2b65f1a18a90638b138f68ac1e0dd38509c547b331991c7fb`

`pb-control.log` contains the command output and exit status. The environment
report identifies the resolved Nix store source paths and tool versions.
