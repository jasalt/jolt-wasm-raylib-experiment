# EXP-014 target patches

## Jolt narrow-fixnum hash/HAMT patch

### Upstream and base

- Project: Jolt
- Base revision: `447b874d06066d15fee187200fabaf410f4ff5b6`
- Patch: [`jolt-tpb32l-word-size.patch`](jolt-tpb32l-word-size.patch)

The patch is applied only to a copied exact-revision Jolt source tree. It does
not change the project pin or the sibling checkout.

### Problem and no-patch reproduction

The first attempt ran Jolt's machine-neutral source-emission stages on the
32-bit target interpreter itself. That is not the documented cross-build
split, and it failed before `flat.ss` at:

```text
Exception in fx>=?: 2147483648 is not a fixnum
```

Using a `tpb64l` build host and a `tpb64l`-loadable `tpb32l` xpatch correctly
moves only Jolt build step 4 to the target. Stock Jolt then mints a genuine
`tpb32l` FASL and boot, but the resulting target aborts during runtime startup:

```text
Exception: variable murmur3-seed is not bound
```

A correctness-first replacement of the hash engine's unsafe fixnum operations
advanced to `fxsra: 704819571 is not a fixnum`, and converting the HAMT's
32-bit hash/bitmap operations advanced to `fxsll: fixnum overflow with
arguments 1 and 30`. These are one word-size defect: Jolt assumes that every
Java 32-bit int and unsigned HAMT bitmap fits Chez's fixnum domain. On
`tpb32l`, `most-positive-fixnum` is only `536870911`.

The retained logs are:

- `artifacts/logs/EXP-014/jolt-tpb32l-compile.log`
- `artifacts/logs/EXP-014/jolt-tpb32l-host64-compile.log`
- `artifacts/logs/EXP-014/jolt-tpb32l-portable-hash-compile.log`
- `artifacts/logs/EXP-014/jolt-tpb32l-portable-hash-native-run.log`

### Patch intent and changed files

The patch preserves Java/Clojure 32-bit hash values and map semantics:

- `host/chez/hasheq.ss` selects the existing unsafe fixnum chain only when the
  complete unsigned 32-bit range is a Chez fixnum; narrow-fixnum targets use
  generic exact-integer operations.
- `host/chez/collections.ss` applies the same split to HAMT hashes and bitmaps,
  including bit 30.
- `test/chez/tpb32l-hash-test.ss` is an exact-target regression with JVM-golden
  Murmur3 values and explicit 32-bit fold/multiply rows.

This does not alter mutexes, conditions, threads, Jolt integer semantics, or
application source. Project-local configuration cannot make `#3%fx*` accept a
bignum or make bit 30 fit a 29-bit positive fixnum, so a source correction is
required.

### Validation and current boundary

Observed validation:

- native `tpb64l` `make hasheq`: 60 checks, 0 failures;
- Jolt `portcheck`, `adaptercheck`, and `manifestcheck`: pass;
- generated native `tpb32l` target regression: `TPB32L-HASH-OK`, exit 0;
- unchanged `app.witness` cross-build: target `flat.so` and `jolt.boot` minted,
  exit 0;
- resulting 32-bit native application advances past both hash/HAMT failures and
  next aborts at Chez `foreign-procedure`: `protocol not supported (libffi
  unavailable)`, exit 134.

The patch therefore sustainably removes the reduced Jolt/Chez-host word-size
blocker and restores genuine boot minting. It does **not** establish T3: the
next independent boundary is Jolt's eager POSIX FFI setup on a portable-bytecode
kernel without libffi. Emscripten behavior remains unclaimed.

### Upstream disposition

The diagnosis and fix were proposed as Jolt PR
[#801](https://github.com/jolt-lang/jolt/pull/801) and merged in commit
`b6ea66bf9180ea63c0dbfe22079a613feb8378b1`. Upstream's reviewed form replaces
the patch's repeated literal tests with `define-width-op`, adds the
`JOLT_NARROW_HASH` expansion gate, and preserves wide-target code generation.
The retained patch remains the exact historical delta for Jolt base
`447b874d06066d15fee187200fabaf410f4ff5b6`; do not apply it to current Jolt.
Its current SHA-256, including the provenance header, is
`d5eda87119768c3cb4ac634b809ae53e94406b6bbed9e943d7290b493eabc92a`.

## Chez Emscripten/libffi compatibility patch

### Upstream and base

- Project: Chez Scheme
- Base revision: `7fadeee45fcc0135b17f5c1a926157004f898339`
- Patch: [`chez-emscripten-libffi.patch`](chez-emscripten-libffi.patch)
- Static library: cross-built libffi 3.5.2

This is independent of Jolt PR #801 and PR #802. Those change Jolt's hash
implementation and public FFI API; this patch adapts the lower Chez
portable-bytecode runtime and Emscripten linkage.

### Purpose

**Succinctly:** this patch enables Chez portable-bytecode foreign calls and
callbacks under WebAssembly by fixing 32-bit argument alignment, representing
libffi closures as Wasm function-table indices, exporting the required
Emscripten table/runtime functions, and exposing statically registered symbols
without browser `dlopen`.

It does not itself add libffi. EXP-014 separately cross-builds and statically
links libffi 3.5.2, then configures Chez with `--enable-libffi`.

### Changed runtime boundaries

- `s/pb.ss` and `c/ffi.c` agree on 8-byte arena alignment for `double`,
  `float`, and 64-bit integer arguments on 32-bit portable-bytecode targets.
- `c/ffi.c` and `s/prims.ss` encode Emscripten libffi closure code as boxed Wasm
  function-table indices rather than pretending those indices are native code
  addresses.
- `configure` exports `addFunction`/`removeFunction`, required memory helpers,
  and a growable function table for libffi closures.
- `c/foreign.c` adds `Sforeign_lookup`, allowing an Emscripten host to resolve
  names registered with `Sforeign_symbol` when `dlopen`/`dlsym` is unavailable.

### Scope in later experiments

EXP-015 through EXP-017 inherit the patched Chez/libffi build. Their scalar
`jolt.ffi/defcfn` calls use it to reach statically registered C functions in the
threaded Wasm module. EXP-017 directly exercises scalar foreign calls, not every
closure or 64-bit alignment branch; those broader changes remain part of the
single EXP-014-validated runtime delta.

### Validation and status

With the patch and static libffi, unchanged canonical Jolt output matched the
native fixture under threaded Node Wasm and subsequently passed Chromium gates.
The patch is still a project-local Chez delta; no merged upstream Chez change is
claimed. SHA-256: `6a630204b734b06361cc74a2c75204eda29095e20debacbd43367c1b391f1a16`.
