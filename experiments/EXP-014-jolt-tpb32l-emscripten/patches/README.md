# EXP-014 Jolt patch

## Upstream and base

- Project: Jolt
- Base revision: `447b874d06066d15fee187200fabaf410f4ff5b6`
- Patch: [`jolt-tpb32l-word-size.patch`](jolt-tpb32l-word-size.patch)

The patch is applied only to a copied exact-revision Jolt source tree. It does
not change the project pin or the sibling checkout.

## Problem and no-patch reproduction

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

## Patch intent and changed files

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

## Validation and current boundary

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

## Upstream suitability

The change is suitable for upstream review because it retains the measured
64-bit unsafe path, adds an actual 32-bit target regression, and makes no
browser- or experiment-specific semantic concession. Patch SHA-256:
`d9d26bd2192be705d5f028683a1ddeca060bd095e9ff27807b071b95edad60be`. Upstream should review
the generated code/performance of the literal `fixnum?` selection on supported
64-bit Chez targets before merging.
