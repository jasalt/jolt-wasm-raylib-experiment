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

**Observed 2026-08-31:** Chez's stock `tpb64l` target build and target pack
were created successfully in the Nix-controlled build directory. Jolt then
failed before emitting the app because the target pack's `xpatch` contains
FASL objects from Chez `10.5.0-pre-release.1`, while the Nix-built Jolt launcher
invoked `/usr/bin/scheme` with an incompatible FASL version:

```text
Exception: incompatible fasl-object version 10.5.0-pre-release.1 found in .../pack/xpatch
```

No Jolt target output was claimed.

## Result

**Reduced blocker — `JOLT_CHEZ_HOST`:** the target pack and Jolt cross-build
boundary require an exact matching native Chez compiler/runtime. The current
Nix Jolt package uses the system/native Chez version and cannot consume the
pinned target pack's FASLs.

## Next step

Build the native Jolt launcher using the same pinned Chez source revision (or
produce the target pack with the exact native Chez version used by the launcher),
then rerun this unchanged pure app. Do not substitute the system Jolt or claim
Node parity from target-pack creation alone.
