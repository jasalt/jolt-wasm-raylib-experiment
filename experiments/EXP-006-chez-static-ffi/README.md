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

## Actual

**Observed 2026-08-31:** `project-custom-init.patch` applies only to the copied
Chez worktree and defines `CUSTOM_INIT` as `project_init`, which registers nine
project-owned symbols with `Sforeign_symbol`. Emscripten pre-registers its boot
files; pinned `c/main.c` consequently does not invoke `CUSTOM_INIT` in that
mode. The patch therefore calls the same idempotent registration function after
`Sbuild_heap`, where the static foreign table is available. The registration is
compiled into `em-pb/bin/pb/scheme.wasm`; it uses neither `dlopen` nor libffi.

The unmodified control rejects `project_noarg` during foreign-procedure setup
(exit 255, `no entry`). The patched Node module prints `EXP-006-NOARG-OK`; the
separate signed witness prints `SIGNED-OK`. These prove the no-argument and
signed-32 static paths in the same Emscripten module.

Focused reductions identify the remaining boundary rather than extrapolating:

- `unsigned-32` reports `protocol not supported (libffi unavailable)`.
- both `ptr` and `void*` identity attempts enter Wasm then trap with `null
  function or function signature mismatch`.
- UTF-8 and allocation tests depend on those pointer/protocol paths and are
  therefore not claimed as passing.

The recorded fallback is a C-owned command/config buffer addressed through
proven signed scalar operations, with C copying UTF-8 and explicit
create/write/read/destroy ownership. It is the measured narrow-wrapper route,
not a libffi substitution.

## Result

**Partial PASS / reduced `CHEZ_PB_ABI`:** static registration, no-argument, and
signed `integer-32` calls work under Node. Unsigned, pointer, string, and
foreign-memory shapes are explicitly unsupported or trap in this pinned
Emscripten portable-bytecode configuration. The complete ABI matrix is in
[PLAN.md](../../PLAN.md#exp-006-observed-portable-bytecode-matrix).

## Artifacts

```sh
nix develop -c ./experiments/EXP-006-chez-static-ffi/commands.sh
```

- `project-custom-init.patch` — named project patch for Chez
  `7fadeee45fcc0135b17f5c1a926157004f898339`
- `witness-noarg.ss`, `witness.ss` — passing control and expanded reduction
- `artifacts/logs/EXP-006/unmodified-control.log`
- `artifacts/logs/EXP-006/noarg-node.log`
- `artifacts/logs/EXP-006/signed.log`, `unsigned.log`, `pointer.log`, and
  `pointer-ptr.log`
