# EXP-008 — Pure Jolt browser payload boundary

## Problem

Run the genuine pure-Jolt source emitted by the exact revision-matched compiler
as a pinned Chez portable-bytecode boot before adding browser graphics or FFI.

## Reproduction

After EXP-004 has emitted `app.build/flat.ss` and EXP-006 has built pinned `pb`:

```sh
nix develop -c ./experiments/EXP-008-jolt-browser/commands.sh
```

The script does not reuse the incompatible `tpb64l` FASL. It recompiles Jolt's
5.8 MB emitted Scheme source with the pinned native `pb` compiler and makes a
22 MB `pb` boot from the resulting 19 MB FASL. Running that genuine boot on
native `pb` aborts before app startup:

```text
Call error: (1 0 #{make-mutex *top*:make-mutex} ())
exit_status=134
```

Preloading the same `pb` boot into the Emscripten `pb` module reaches the same
startup region and aborts in Wasm. Configuring pinned Chez with
`--threads --pb --emscripten` fails earlier because the checkout contains only
`pb` boots, not the inferred `tpb` boot:

```text
No suitable machine type found in "./boot".
Available machine types:
  pb
```

This matches Jolt's own `host/scheme-adapter/THREADS.md`: the no-threads browser
semantics are design-only and “no degraded implementations exist yet.” The
emitted runtime has 113 `make-mutex`, 30 `make-condition`, and 24 `fork-thread`
call sites, so shadowing one startup call would not establish Jolt semantics.

## Result

**Reduced blocker — `JOLT_THREADLESS_ADAPTER`:** exact-host Jolt emission and
`pb` recompilation succeed, but the genuine Jolt runtime cannot initialize on
the only pinned Emscripten Chez target. No pure Jolt browser readiness, fixture
parity, Jolt FFI declaration, or Jolt-driven Raylib frame is claimed. EXP-007's
Scheme declaration remains the smallest verified facade shape; it must not be
relabeled as Jolt.

## Evidence

- `artifacts/logs/EXP-008-native-pb.log`
- `artifacts/logs/EXP-008-node-wasm.log`
- `artifacts/logs/EXP-008-threaded-em-build.log`
- Jolt `447b874d06066d15fee187200fabaf410f4ff5b6`
- Chez `7fadeee45fcc0135b17f5c1a926157004f898339`
