# Gotchas

## Pin source and toolchain inputs

**Status: proposed control.** The project must not rely on an activated mutable
`emsdk` or machine-local checkout paths. `flake.nix` and `pins.edn` define the
intended source/tool boundary; experiments record the exact resolved revisions.

## Jolt requires threads before application startup

**Observed 2026-08-31.** A genuine Jolt-emitted source payload compiles into a
pinned Chez `pb` boot, but loading it aborts at top-level `make-mutex`. The
Emscripten checkout has `pb` boots only, while `--threads --pb --emscripten`
requires an unavailable `tpb` boot. Jolt's `host/scheme-adapter/THREADS.md`
confirms threadless semantics are design-only and not implemented. Do not mask
one mutex call or relabel the Chez-only EXP-007 frame as Jolt.

## Pin source inputs as tarballs with content hashes

**Observed 2026-08-31.** Git-input locking began downloading a large full Chez
repository and exceeded a 600-second command budget. Replacing the four
immutable source inputs with revision-addressed GitHub tarballs let
`nix flake lock --option connect-timeout 30` complete and record NAR hashes in
`flake.lock`. The Jolt source cannot use a plain archive because its
`vendor/irregex` submodule is required by the build; the Jolt input therefore
uses a revision-pinned Git input with `submodules=1`. `nix develop -c
./scripts/test-native` has built that pinned package and passed the witness.
