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

Current boundary: `tpb32l` boots **yes**; threaded Chez/Node **yes**, fixed pool
1; genuine patched Jolt boot minted **yes**; Jolt/Node **yes**, canonical
output parity, exit 0; Chez/Chromium, **T0–T6 PASS.** Threaded Chez, full Jolt, and named Petite Jolt now pass under
Chromium with cross-origin isolation and canonical output parity.

## Minimal reproduction

```sh
nix develop -c ./experiments/EXP-014-jolt-tpb32l-emscripten/commands.sh jolt-node
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

**T0–T3 PASS.** The current workspace retains the known non-threaded Jolt
boundary, stock pinned Chez generated `tpb32l` material, a deterministic
native threaded target, the same witness under Emscripten pthreads/Node, and
genuine Jolt under threaded Node Wasm with canonical output parity.

**Historical no-patch failure:** running Jolt's machine-neutral source-emission
stages on the target's 32-bit interpreter stopped before `flat.ss` at
`fx>=?: 2147483648 is not a fixnum` (exit 255). That invocation did not follow
Jolt's documented host/target split. A `tpb64l` host with its own
`tpb32l` xpatch correctly emits target `flat.ss`, FASL, and boot.

**Observed 2026-08-31 — sustainable word-size patch:** stock emitted runtime
then exposed two real narrow-fixnum assumptions: `murmur3-seed` remained
unbound after unsafe 32-bit hash operations, followed by `fxsll` overflow at
HAMT bit 30 under a correctness-first reduction. The experiment-local patch
selects the existing unsafe hash/HAMT path only when all unsigned 32-bit values
fit a Chez fixnum and otherwise uses exact-integer operations. It changes no
thread or integer semantics. Native `tpb64l` hash tests pass 60/60 and the
actual `tpb32l` regression prints `TPB32L-HASH-OK`.

**Observed 2026-08-31 — libffi FFI capability:** stock Jolt's guarded POSIX
foreign-procedure setup aborts on the no-libffi portable-bytecode kernel with
`protocol not supported (libffi unavailable)`, exit 134. Cross-building
static libffi 3.5.2 for Emscripten and applying the reviewed Chez Emscripten
FFI delta (ffi.c, foreign.c, configure, pb.ss, prims.ss) resolves this. The
patched exact-revision Jolt runtime with unchanged canonical `app.exp014`
fixture now mints and runs under threaded Node Wasm:

```text
EXP-004-JOLT-PB-OK
{:unicode λ-東京, :collection [1 2 3]}
allocation 40000
EXP-014-JOLT-COMPLETE
exit_status=0
```

Native expected output matches Node output exactly (4 lines, exit 0).

| Gate | Result | Evidence |
| --- | --- | --- |
| T0 generated `tpb32l` boots | PASS | bootquick log/files/hashes |
| T1 native thread witness | PASS | native thread log |
| T2 Emscripten Chez / Node | PASS | Node/build logs |
| T3 Jolt / Node | PASS | libffi-jolt-node.log, canonical parity |
| T4 Chez / Chromium | PASS | `EXP-014-t4-browser.json`, headers, screenshot |
| T5 Jolt / Chromium | PASS | `EXP-014-t5-browser.json`, screenshot |
| T6 Petite Jolt / Chromium | PASS | `EXP-014-t6-browser.json`, size/hash comparison |

## Suspected layer

The retained `pb` control remains `JOLT_THREADLESS_ADAPTER`. On `tpb32l`, the
defects are repaired, Jolt runs under threaded Node Wasm, and genuine Jolt
runs under Chromium pthread workers, including named Petite. EXP-014 has no
remaining runtime gate.

## Workaround or next experiment

The threaded-Jolt runtime route is demonstrated through T6. Downstream work is
Jolt-to-Raylib integration; do not infer a Raylib or input result from EXP-014.

## Upstream suitability

The exact-base, regression-covered patch is proposed for upstream review. See
[`patches/README.md`](patches/README.md) for its rationale, changed files,
validation, and remaining boundary.

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
- `artifacts/logs/EXP-014/jolt-tpb32l-pack.log` — generated pack assembly,
  exit 0; its xpatch, Petite, and Scheme boot SHA-256 values are respectively
  `b739d6d84ff9076e36819945d668f2c66ee23da8b50b915c41e8aef8607c8126`,
  `1c24a015d26cc143caea9b05f334a9a9be5160d3670ac0536aab9a32a9e7e59c`,
  and `7d6e47c2d91aad482b53ff7199a535eeb644834acc45ebd43b6a8b1f16024ac6`.
- `artifacts/logs/EXP-014/jolt-tpb32l-compile.log` — historical target-host Jolt
  invocation and the `fx>=?` failure, exit 255.
- `artifacts/logs/EXP-014/tpb32l-fixnum-boundary.log` — target machine,
  threaded state, maximum fixnum, and minimal primitive reproduction.
- `artifacts/logs/EXP-014/host64-build-and-bootquick.log` and
  `host64-target-kernel.log` — one exact Chez tree built as the `tpb64l` host,
  generated its `tpb32l` xpatch, and built the target kernel. Pack xpatch,
  Petite boot, Scheme boot, and kernel hashes are respectively
  `510a781d1a279b631decc4624b9dfb77053b7918151321be1e982868ee70b3be`,
  `bc9a40acebed0d2436b654d61ea68bb3860a87b457dd33a22f1b6bfa3d3467e5`,
  `4a9aeb030e6ba4845e7e31ac7280a5e143d3b2476c144450e58e3d0353547e90`,
  and `5c92b7db4468955a4dabc263614da314cb77fa46166f58700f4957bb18383f83`.
- `artifacts/logs/EXP-014/host64-hasheq-test.log` — 60/60 existing hash checks.
- `artifacts/logs/EXP-014/tpb32l-hash-test.log` — `TPB32L-HASH-OK`, exit 0.
- `artifacts/logs/EXP-014/jolt-tpb32l-patched-mint.log` — genuine target FASL
  and boot minting, exit 0.
- `artifacts/logs/EXP-014/jolt-tpb32l-patched-native-run.log` — first later FFI
  capability failure, exit 134.
- `experiments/EXP-014-jolt-tpb32l-emscripten/patches/jolt-tpb32l-word-size.patch`
  — SHA-256 `d5eda87119768c3cb4ac634b809ae53e94406b6bbed9e943d7290b493eabc92a`.
- `experiments/EXP-014-jolt-tpb32l-emscripten/patches/chez-emscripten-libffi.patch`
  — SHA-256 `6a630204b734b06361cc74a2c75204eda29095e20debacbd43367c1b391f1a16`.
- `artifacts/logs/EXP-014/libffi-jolt-node.log` — threaded Node Wasm Jolt
  output, exit 0; SHA-256 `19f60fe4f7dba3f2fb37a6056c3745ee94bccff6a43923502c1071909cf59d6a`.
- `artifacts/logs/EXP-014/libffi-jolt-native-expected.log` — native expected
  output, exit 0; SHA-256 `943e410459f1f92981fe5ad4d15f2ed205595270418b4d8d9ab381c5bd830db8`.
- `artifacts/logs/EXP-014/libffi-jolt-hashes.txt` — patch, boot, and runtime
  SHA-256 values for the T3 run.
- `artifacts/logs/EXP-014/emscripten-thread-pool-1-build.log` — stock pinned
  Chez configured `--emscripten --threads --pbarch --emboot=witness-thread.boot`
  with named `-s PTHREAD_POOL_SIZE=1`; compile and final link both contain
  `-pthread` and exited 0.
- `artifacts/logs/EXP-014/node-thread-pool-1.log` — Node printed Chez startup
  and `THREAD-WITNESS-OK`, exit 0. The first default and named pool=1 attempts
  hung because the early witness did not set `scheme-start`; the final exact
  same pool=1 build uses the boot's `scheme-start` and exits cleanly.
- `artifacts/logs/EXP-014/t4-headers.txt`, `t4-server.log`, and
  `t4-chromium.log` — T4 loopback server headers and browser diagnostics.
  `artifacts/reports/EXP-014-t4-browser.json` records Chromium 152.0.7977.64,
  `crossOriginIsolated: true`, SharedArrayBuffer availability, no page errors
  or request failures, and the `THREAD-WITNESS-OK` output. The inspected full
  page screenshot is `artifacts/screenshots/EXP-014/threaded-chez/page.png`:
  it visibly shows the Emscripten page and terminal output containing
  `THREAD-WITNESS-OK`. SHA-256: browser report
  `026370554d7b2ab862a0b3d80a274d4a20ee551d8f65b67dc207b85cf8d38eb4`;
  page screenshot
  `2c5c7d8a9e991101cc0576656f5d6284e77b4e3a295e695ab98b94b7a95be540`;
  response headers
  `e62c1c28e22a0e075acbfd14a0950997218226be4629bff73ce0d0fc01950133`.
- `artifacts/logs/EXP-014/t5-headers.txt`, `t5-server.log`, and
  `t5-chromium.log` — T5 loopback headers and browser diagnostics.
  `artifacts/reports/EXP-014-t5-browser.json` records Chromium,
  `crossOriginIsolated: true`, SharedArrayBuffer availability, the exact four
  canonical output lines, and no page errors. The only request failure is the
  Emscripten clean-exit cancellation (`net::ERR_ABORTED`, `canceled: true`),
  retained verbatim and excluded from actionable failures. The inspected page
  screenshot `artifacts/screenshots/EXP-014/threaded-jolt/page.png` visibly
  shows all four lines, including Unicode `λ-東京` and
  `EXP-014-JOLT-COMPLETE`. SHA-256: report
  `a6c86ce36390df43996dad95ee7332c738232cd4363856d1ea9ecb5f8729920b`;
  screenshot
  `ba33bfc886d4f5817081b7bf2b1299b406c088adf2091129f4423f9c375c47e4`.
- T6 named `--empetite` build links only `petite.boot` and `jolt.boot`, not
  `scheme.boot`; it runs the exact fixture in Chromium. Full/Petite byte sizes:
  JS `125169`/`125115`, Wasm `891643`/`891643`, data `25377348`/`24337546`.
  Full/Petite data SHA-256 values are respectively
  `cba13a2b614177d301da62dc885fc3589e724e38720226e1cc755bbab2a0840b` and
  `48546f4129095f5720b717e3ef8229148c59dfacbf3c10f009ec2736d6dbc0bb`.
  `artifacts/reports/EXP-014-t6-browser.json` SHA-256 is
  `793e21de88811a66c601bf2acb4476ed33b4230d473c758ab9d334f6e161475a`.
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
