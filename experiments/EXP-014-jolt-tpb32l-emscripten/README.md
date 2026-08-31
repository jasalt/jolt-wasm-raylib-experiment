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

**Observed 2026-08-31 — control:** `commands.sh control` reran the genuine
EXP-008 control. It compiled the Jolt-emitted `flat.ss`, then aborted at:

```text
Call error: (1 0 #{make-mutex *top*:make-mutex} ())
exit_status=134
```

**Observed 2026-08-31 — T0:** a fresh writable copy of the exact pinned Chez
source was configured as a portable `pb` build (host machine `pb`), built, and
then ran the documented command:

```sh
make bootquick XM=tpb32l
```

It completed with exit 0, reporting `building boot files for tpb32l using pb`.
It produced `boot/tpb32l/petite.boot`, `boot/tpb32l/scheme.boot`, and the
cross-compiler material including `xc-tpb32l/s/xpatch`. The generated boot
hashes are listed below. This proves target boot generation only; it does not
prove a thread can run or that an Emscripten module is viable.

The `pb` control is not a Jolt browser success. It preserves the existing
`JOLT_THREADLESS_ADAPTER` boundary for non-threaded `pb`.

## Investigation

Pinned Chez `BUILDING` identifies `make bootquick XM=tpb32l` (or Zuo's
equivalent) as the stock cross-boot mechanism. Pinned `configure` sets the
Emscripten word size to 32 and maps threaded 32-bit PB to `tpb32l`; its
`bootquick` target builds the cross compiler and writes the target boot files
plus `xc-tpb32l/s/xpatch`. The experiment used that documented route without an
upstream patch.

`witness-thread.ss` uses the pinned Chez forms `fork-thread`, `make-mutex`,
`mutex-acquire`, `mutex-release`, `make-condition`, `condition-wait`, and
`condition-signal`. Its predicate loop accounts for a wake before state
publication. The normal 64-bit dev shell has no 32-bit multilib headers, so the
flake now exposes its locked `pkgsi686Linux.stdenv.cc` as `i686-cc`; this is a
pinned Nix cross-toolchain, not an unrecorded host SDK.

**Observed 2026-08-31 — T1:** under that compiler, a fresh target-compatible
native configuration used `--threads --pbarch --32` and produced an ELF
32-bit `tpb32l/bin/tpb32l/scheme`. The witness printed `THREAD-WITNESS-OK` and
exited 0. An earlier attempt using the 64-bit shell's `gcc -m32` failed before
Chez compilation because `gnu/stubs-32.h` was absent; that setup was rejected
as an `ENVIRONMENT` issue and was not treated as a Chez result.

## Result

**T0–T2 PASS / later target status not yet run.** The current workspace
retains the known non-threaded Jolt boundary, stock pinned Chez generated
`tpb32l` boot and cross-compilation material, an actual 32-bit native threaded
target completed deterministic cross-thread communication, and the same witness
completed through the Emscripten pthread module under Node. T3 through T6 are
not established.

| Gate | Result | Evidence |
| --- | --- | --- |
| T0 generated `tpb32l` boots | PASS | bootquick log/files/hashes |
| T1 native thread witness | PASS | native thread log |
| T2 Emscripten Chez / Node | PASS | Node/build logs |
| T3 Jolt / Node | not run | — |
| T4 Chez / Chromium | not run | — |
| T5 Jolt / Chromium | not run | — |
| T6 Petite Jolt / Chromium | not run | — |

## Suspected layer

The retained control is `JOLT_THREADLESS_ADAPTER` on `pb`. It does not classify
the untested `tpb32l` route.

## Workaround or next experiment

Proceed to T3 only: mint the unchanged genuine Jolt application boot for the
generated `tpb32l` target. Do not patch Jolt, add `PROXY_TO_PTHREAD`,
substitute a host Scheme, or mix in Raylib/FFI work.

## Upstream suitability

No upstream patch is proposed. See [`patches/README.md`](patches/README.md) for
the no-patch discipline.

## Artifacts and hashes

Ignored reproducibility logs created by `control`:

- `artifacts/logs/EXP-014/bootstrap.log` — SHA-256
  `e5009ccd95940239f7d5ac93188d54c2613a4854bb93a5900aeb64733f6a7396`
- `artifacts/logs/EXP-014/pb-control.log` — SHA-256
  `2b13fce449e33bd0440070d46ff0137805c38fc4eb65a6136b2c2363f0bf67a6`
- `artifacts/logs/EXP-014/bootquick-tpb32l.log` — SHA-256
  `4a160b507621fbee213181e4563d5adf7edc4de5f471389a7fa96c57595cd6a0`
  (exit 0)
- `artifacts/logs/EXP-014/bootquick-files.txt` — SHA-256
  `c9656cb4a6856815c014bb136ca46b66395435290775bdd647e9ff06a10ff58f`
- `artifacts/logs/EXP-014/bootquick-hashes.txt` — SHA-256
  `18e173bf96af8b98c5a01474078932bbe8aa765c0f01e75d9e0709aa1eaae239`;
  the key boot hashes are `petite.boot`
  `abc458e90f3434f9c368aec41e77688621372dd9f1dedfb5707d7efe5113e733`,
  `scheme.boot`
  `61c24a66befa23177e37bdea90e95ffb72f566aa3194748eee6c80cc223212cd`,
  and `xpatch`
  `6e54168b8552aa7b31754678d565c40a5a72853e92660cd8f67d6d8898ae9d63`.
- `artifacts/logs/EXP-014/emscripten-thread-pool-1-build.log` — stock pinned
  Chez configured `--emscripten --threads --pbarch --emboot=witness-thread.boot`
  with named `-s PTHREAD_POOL_SIZE=1`; compile and final link both contain
  `-pthread` and exited 0.
- `artifacts/logs/EXP-014/node-thread-pool-1.log` — Node printed Chez startup
  and `THREAD-WITNESS-OK`, exit 0. The first default and named pool=1 attempts
  hung because the early witness did not set `scheme-start`; the final exact
  same pool=1 build uses the boot's `scheme-start` and exits cleanly.
- `artifacts/logs/EXP-014/native-thread-witness.log` — an ELF 32-bit
  `tpb32l` build followed by `THREAD-WITNESS-OK`, exit 0.
- `artifacts/logs/EXP-014/native-tpb32l-32bit-build.log` — full pinned i686
  build and witness command, exit 0.
- `artifacts/logs/EXP-014/tpb64l-api-control.log` — API control for the same
  witness, exit 0; this is not substituted for the T1 target result.
- Existing immutable EXP-008 evidence:
  `artifacts/logs/EXP-008-native-pb.log` — SHA-256
  `dcbb6a2ab1ccb7e2b65f1a18a90638b138f68ac1e0dd38509c547b331991c7fb`

`pb-control.log` contains the command output and exit status. The environment
report identifies the resolved Nix store source paths and tool versions.
