# EXP-004 — Pure Jolt target boot under Node

## Problem

Run a pure Jolt application through a target-compatible Chez Emscripten
portable-bytecode payload.

## Environment

Pinned Jolt `447b874d`; pinned Chez `7fadeee45fcc0135b17f5c1a926157004f898339`;
Nix shell; target prepared with stock Chez `tpb64l` cross tools.

## Minimal reproduction

```sh
CHEZ_SRC=$PWD/build/EXP-003-jolt-tpb32l/source \
  ../jolt/tools/cross-compile/make-pack.sh tpb64l build/EXP-003-jolt-tpb32l/pack
cd experiments/EXP-004-jolt-node
JOLT=$(nix build --no-link --print-out-paths ../..#jolt)
"$JOLT/bin/jolt" build -m app -o ../../build/EXP-004-jolt-node/app \
  --target tpb64l --target-pack ../../build/EXP-003-jolt-tpb32l/pack
```

## Expected

Jolt cross compiler emits a target boot payload and Node executes the pure app.

## Actual

**Original observation, retained:** the prior run selected `/usr/bin/scheme`,
which rejected the target-pack `xpatch` FASL. That was a host-selection failure,
not a Jolt target result.

**Remediation observation, 2026-08-31:** the rerun explicitly selected
`build/EXP-003-jolt-tpb32l/source/tpb64l/bin/tpb64l/scheme`, from pinned Chez
`7fadeee45fcc0135b17f5c1a926157004f898339`. It reports Chez
`10.5.0-pre-release.1`, machine `tpb64l`, and `threaded?` `#t`. `JOLT_CHEZ` was
that absolute executable and `JOLT_CHEZ_CSV` was the matching target pack;
Jolt was `447b874d06066d15fee187200fabaf410f4ff5b6`.

The incompatible-FASL error did **not** recur: Jolt loaded, emitted the pure
`app.witness` flat source, and the exact-host compiler created `flat.so`.
The first later boundary was native executable linking, exit 1:

```text
ld.bfd: cannot find -llz4
ld.bfd: cannot find -lz
```

The target requested (`tpb64l`) equals the exact native compiler machine, so
Jolt correctly treats it as a native-target build rather than applying the
cross `xpatch` path. Its native link flags use the host CSV prefix, while the
Nix experiment's generated target pack keeps `liblz4.a` and `libz.a` under
`pack/lib/`. A temporary copy of those archives exposed the next missing host
link dependency, `-luuid`; it did not produce an app executable. This is a
reduced `JOLT_CHEZ_HOST`/native-link toolchain boundary, after genuine host
compatibility, not a replacement of the target result with host `a6le` output.

## Result

**Reduced blocker — `JOLT_CHEZ_HOST`:** exact revision-matched host selection
works through Jolt emission and target compilation. Native target linkage is
not reproducibly configured for this standalone threaded-pb compiler/CSV layout
under the pinned Nix shell. No Emscripten package, Node execution, or fixture
parity is claimed.

## Next step

Prepare a genuine Emscripten `pb` target pack and a matching native Chez host
CSV/link configuration (including its static dependencies), then rerun the
unchanged pure witness. Do not substitute `/usr/bin/scheme`, host `a6le`, or an
unverified native executable for the target payload.

## Artifacts and hashes

- `experiments/EXP-004-jolt-node/commands.sh` — exact-host reproduction
- `artifacts/logs/EXP-004/exact-host-metadata.log`
- `artifacts/logs/EXP-004/exact-host-cross-build.log` (post-host failure)
- `artifacts/logs/EXP-004/exact-host-native-target-build.log` (controlled
  static-library layout probe; exit 1 at `-luuid`)
- `artifacts/logs/EXP-004/exact-host-cross-build-override.log` (shows target
  flags are not selected when target machine equals host)
