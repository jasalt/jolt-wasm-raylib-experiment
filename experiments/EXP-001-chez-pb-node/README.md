# EXP-001 — Stock Chez portable bytecode under Node

## Problem

Determine whether unmodified pinned Chez can build its portable-bytecode
interpreter through its upstream Emscripten path and execute it under Node.

## Hypothesis

A native `pb` build can create the required stock portable boot payload; an
`--emscripten --empetite` build then preloads that runtime and runs it under
Node.

## Environment

- Chez source: `7fadeee45fcc0135b17f5c1a926157004f898339`, including required
  `zuo` and `zlib` submodules.
- Emscripten: `6.0.8-git` from the locked Nix shell.
- Node: supplied by the locked Nix shell.
- Target: stock non-threaded `pb` portable-bytecode interpreter.

## Minimal reproduction

```sh
nix develop -c ./experiments/EXP-001-chez-pb-node/commands.sh
```

The build copies the immutable pinned source with dereferenced submodules into
an ignored writable work area. It builds native `pb` to mint the target boot
files, then builds `pb --emscripten --empetite`, so only stock petite runtime
boot payload is preloaded. The Node witness supplies Scheme source through
standard input.

## Expected

Node prints the witness token, target machine type, exact/inexact arithmetic
results, and exits successfully after allocation plus an explicit collection.

## Actual

**Observed 2026-08-31:** the command exited 0. Node ran the generated
`em-pb/bin/pb/scheme.js` and printed:

```text
EXP-001-PB-OK
pb
42
3.75
```

The witness allocates 100,000 pairs and calls `collect` before reporting the
machine type and arithmetic. The runtime banner identifies `Petite Chez Scheme
Version 10.5.0-pre-release.1`.

## Investigation

A plain GitHub source archive was an invalid pin boundary: it omitted Chez
submodules, causing `Source in "zuo" is missing`. The source input is now a
revision-pinned Git input with `submodules=1`; the lock records the exact
revision and NAR hash. No Chez source patch was applied.

This is the smallest stock non-threaded control. `tpb32l` remains unproven and
must be a separate witness before drawing conclusions about Jolt's threaded
requirement.

## Result

**Observed — `CHEZ_EMSCRIPTEN`:** stock Chez `pb` portable bytecode executes
under Node through the upstream Emscripten path. This does not establish
threaded `tpb32l`, browser execution, Jolt compatibility, static FFI, or
Raylib integration.

## Suspected layer

Not applicable; the `pb` Node control succeeded.

## Workaround or next experiment

Use this exact source preparation in a separate `tpb32l` candidate experiment;
do not silently treat this non-threaded result as Jolt compatibility.

## Upstream suitability

No upstream patch or workaround. The submodule requirement is a project pinning
correction, not a Chez defect.

## Artifacts and hashes

- `artifacts/logs/EXP-001/build.log`
- `artifacts/logs/EXP-001/node.log`
- ignored generated output: `build/EXP-001-chez-pb-node/source/em-pb/bin/pb/`

The logs preserve full commands, compiler output, Node banner, witness output,
and process status.
