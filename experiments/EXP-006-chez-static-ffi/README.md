# EXP-006 — Static Chez portable-bytecode FFI facade

## Problem

Determine whether the stock Chez portable-bytecode target can call project-owned
statically linked C symbols without dynamic loading.

## Environment

Pinned Chez `7fadeee45fcc0135b17f5c1a926157004f898339`, Emscripten
`6.0.8-git`, and Nix shell. The prior EXP-001 `pb` Node build is the control.

## Investigation

The pinned Chez source confirms that portable bytecode exposes
`foreign-procedure` and that static entries are registered with
`Sforeign_symbol(name, address)` in the C startup layer. The stock source
registers its own `(cs)` entries in `c/foreign.c`, but there is no project facade
or registration hook in the unmodified experiment output.

The portable prototype surface observed in Chez source includes `integer-32`,
`unsigned-32`, `string`, `ptr`, `u8*`, and `scheme-object` shapes. Those are the
candidate rows for the required matrix:

```text
Jolt declaration -> emitted Chez type list -> pb prototype -> C facade -> owner/lifetime -> witness
```

## Result

**Reduced blocker — `CHEZ_PB_ABI` / `JOLT_FFI`:** EXP-001 proves the stock
interpreter boots, but this task cannot honestly claim a static custom C call
until the startup registration point is project-owned and compiled into the
same Emscripten module. No dynamic `dlopen` or unsupported `libffi` path was
substituted. The required scalar, pointer, UTF-8, and foreign-memory rows remain
unproven.

## Next experiment

Add a minimal project-owned registration patch to the copied Chez C startup
source (not upstream), register one no-argument integer-returning symbol, and
run it under Node before expanding the matrix. Keep an unmodified control and
record the exact patch.

## Artifacts

The source/API inspection is reproducible from the pinned Nix shell with:

```sh
grep -RIn 'Sforeign_symbol\|foreign-procedure' "$CHEZ_SOURCE/c" "$CHEZ_SOURCE/s"
```
