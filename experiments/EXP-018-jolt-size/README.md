# EXP-018 — Jolt 0.8.21 upgrade and release bundle size

## Problem

Measure the current compiled Flappy Bird artifact before updating Jolt from
`6cb7d2ec4c82201fe54f0685f6c6ff433f106ecf` to requested
`5b46858a171f30949f5b09eb484bc6c5ff93c6ea` (0.8.21). Audit the intervening
[CHANGELOG](https://github.com/jolt-lang/jolt/blob/5b46858a171f30949f5b09eb484bc6c5ff93c6ea/CHANGELOG.md)
for compatibility, not just size.

## Hypothesis

The unchanged signed-int32 facade remains compatible. New release build defaults
may reduce the Jolt boot payload without changing Chez/Raylib Wasm code.

## Environment

Observed 2026-10-11, Fedora 44 x86_64 Lima; [environment.txt](environment.txt).
Chez remains `7fadeee45fcc0135b17f5c1a926157004f898339`, target `tpb32l`, with
the existing EXP-014 libffi and EXP-017 frame-host patches. Raylib remains
`9f3cadf1e618f125bd9b282c7759f8cb26ce17fc`; app and C facade unchanged.
Chromium 152.0.7977.64, Emscripten flags unchanged (pthreads, pool size 1,
assertions, GLFW3). No Jolt source patch. The build host changes from `tpb64l`
to `ta6le` at the **same Chez revision**, with its own matching xpatch; the
Wasm target and target-pack kernel/boots are retained.

## Minimal reproduction

Requires the existing EXP-014/017 build tree; this is not a clean-room bootstrap.
The session first saved the existing outputs, then rebuilt the old revision with
`nix develop -c ./experiments/EXP-017-jolt-flappy/commands.sh` before modifying
pins. Baseline artifacts are retained in ignored `build/EXP-018-baseline/`.

To repeat that baseline with the current parameterized script, prepare an exact
old source tree (the session retained `build/EXP-018-jolt-baseline/`) and run:

```sh
nix develop -c env \
  JOLT_PROJECT_SOURCE="$PWD/build/EXP-018-jolt-baseline" \
  JOLT_PROJECT_REVISION=6cb7d2ec4c82201fe54f0685f6c6ff433f106ecf \
  JOLT_BUILD_CHEZ="$PWD/build/EXP-017-flappy/tpb64l/bin/tpb64l/scheme" \
  JOLT_BUILD_CSV="$PWD/build/EXP-017-flappy/tpb64l/boot/tpb64l" \
  JOLT_TARGET_PACK="$PWD/build/EXP-014-jolt-tpb32l-emscripten/pack-libffi-raylib-input" \
  ./experiments/EXP-017-jolt-flappy/commands.sh
./experiments/EXP-018-jolt-size/commands.sh snapshot-baseline
```

After updating `flake.nix`, `flake.lock`, and `pins.edn`:

```sh
nix develop -c ./experiments/EXP-018-jolt-size/commands.sh prepare
nix develop -c ./experiments/EXP-017-jolt-flappy/commands.sh
./experiments/EXP-018-jolt-size/commands.sh snapshot-updated
./experiments/EXP-018-jolt-size/commands.sh compare
nix build .#jolt --no-link
nix develop -c ./scripts/test-native
```

All final commands exited 0. Raw logs: `artifacts/logs/EXP-018/` (ignored).
`prepare` obtains Jolt including pinned submodules from the Nix input, builds a
native x86_64 Chez host, and regenerates the host-specific `tpb32l` xpatch.

## Expected

A successful latest release-default build, measured separately as `.wasm`, `.js`,
`.data`, and boot; browser readiness, Space and click input, and inspected images.

## Actual

**PASS**, release-default comparison. Exact byte counts:

| Artifact | Old Jolt | 0.8.21 | Change |
| --- | ---: | ---: | ---: |
| `scheme.wasm` | 1,097,110 | 1,097,110 | 0%; identical SHA-256 |
| `scheme.js` | 456,608 | 456,608 | 0% size; content differs |
| `scheme.data` | 26,193,321 | 15,728,775 | −39.951% |
| `jolt.boot` (inside `.data`) | 23,039,902 | 12,575,356 | −45.419% |
| Wasm + JS + data | 27,747,039 | 17,282,493 | −37.714% |
| Same three, gzip-9 | 13,554,413 | 9,182,095 | −32.258% |

Gzip numbers use Python gzip level 9, mtime 0, per-file compression; they are not
measured network transfer sizes. HTML is excluded and boot is **not** counted
twice. Latest compilation says `dropping compiler image (no runtime eval)`;
this compares defaults, not equivalent full-compiler profiles. The exact data
reduction equals the boot reduction. Wasm is the Chez interpreter/C/Raylib
kernel, not native Wasm compilation of Jolt forms. No frame-time, startup-time,
peak-memory or general performance claim is made.

Both browser gates reached readiness and consumed Space plus left click. The
latest report has no page/request errors and confirms isolation/SharedArrayBuffer.
Vision inspection of [page.png](evidence/page.png) and
[canvas.png](evidence/canvas.png): sky-blue field, yellow bird raised toward the
upper-left, dark-green upper/lower pipe pairs with open gaps, `score 0`; page
says `ready: Jolt Flappy Bird (9 commands, 2 flaps)` and shows the canonical
fixture and readiness token. The 800×600 viewport clips the far-right canvas
edge in the canvas capture; the page capture shows the scene. No blank render.

## Investigation

### Changelog/FFI compatibility audit

Compared pinned changelogs and current `host/chez/java/ffi.ss`,
`stdlib/jolt/ffi.clj`, `stdlib/jolt/socket/native.clj`, `host/chez/build.ss`,
`host/chez/hasheq.ss`, and `src/app/exp017.clj`:

- 0.8.0 already changed `ffi/write` to value-before-offset, renamed `layout` to
  `struct`, and made arrays `[:array type count]`. Neither baseline nor this
  app uses those APIs: all three declarations use only signed `:int32`.
- 0.8.1 build direct-link defaults and later compiler-dropping/boot encodings
  change build capabilities/size. The C callback still dynamically resolves the
  live app `frame!` Var. No browser arbitrary-eval capability is claimed.
- 0.8.21 changes float returns/reads/callback arguments to `java.lang.Float`,
  with unboxing on C entry; app uses integer-tenths physics and no float FFI.
- Collect-safe/blocking callbacks and opt-in GC diagnostics changed upstream;
  the bounded scalar command/input facade does not wait or register a Jolt
  foreign-callable callback. C still calls Scheme on the proven frame owner.
  Stock pinned Chez does **not** acquire Jolt release Chez patches merely by
  updating Jolt: do not extrapolate their reported memory/blocking-call gains.
- CAS now compares expected values by identity; app uses `reset!`, not CAS.
  Foreign private-var references are refused (0.8.11); app uses public FFI vars.
  Reader `:bb` was dropped; this app has no such conditional. Non-daemon thread
  lifetime now matters (0.8.16); this app starts no future/agent/executor.
- New zlib/runtime bindings and socket error-convention selection affected the
  **build host** even though the app has no sockets or zip use. This is the
  actual compatibility migration needed here, not an int32 facade rewrite.

### Reduced no-patch failures (preserved, not erased)

1. Bare original script outside `nix develop`: missing `xxd`, exit 1;
   `nix develop` baseline retry passes. **ENVIRONMENT**.
2. A new plain git archive lacks submodules, refused by the launcher, exit 1.
   Use recursive checkout/Nix input. **ENVIRONMENT**.
3. Old no-libffi `tpb64l` host: `protocol not supported (libffi unavailable)`,
   exit 255. [log](evidence/upgrade-submodules.log). **CHEZ_PB_ABI**.
4. Pure latest launcher `-e '(println :latest-hostlib-ready)'` on the existing
   libffi-enabled `tpb64l` host fails without app loading:
   `jolt-ffi-native-error-convention-case: unsupported target machine tpb64l`.
   [log](evidence/latest-hostlib.log). **JOLT_CHEZ_HOST**.
5. Nix Chez 10.4.1 native host loads latest Jolt but cannot consume pinned
   10.5 pre-release xpatch: incompatible FASL version. Matched native Chez
   then cannot consume a `tpb64l`-minted xpatch: incompatible FASL machine type.
   [version log](evidence/upgrade-native-host.log),
   [machine log](evidence/upgrade-matched-host.log). **PROJECT_CODE** tool pairing.
6. Native host from pinned Chez plus regenerated native-host xpatch passes
   Jolt emission, target compilation, Emscripten link and real browser gate.
   No Jolt/Chez source patch was added to solve those host failures.

## Result

Pinned latest Jolt builds and renders the unchanged app. The runtime Wasm size
is unchanged; default preloaded boot/data is substantially smaller. Native Nix
Jolt package build and native project tests also pass.

## Suspected layer

Remaining portable-bytecode **build-host** incompatibility is upstream Jolt
socket error-convention selection. It is not a demonstrated Wasm app failure.

## Workaround or next experiment

Keep the matched native host and host-specific xpatch. Full-compiler size parity,
long-run GC stress and float/aggregate FFI remain unmeasured, separate experiments.

## Upstream suitability

The pure `tpb64l` launcher failure is a reduced report candidate. Native-host
cross compilation is a project build choice, not an upstream patch.

## Artifacts and hashes

[evidence/sizes.json](evidence/sizes.json) contains every artifact hash and raw/
gzip byte count. [evidence/SHA256SUMS](evidence/SHA256SUMS) hashes the small
committed reports, failure logs and screenshots. Generated Wasm/JS/data/boots,
profiles and caches remain ignored; the two snapshots are in `build/EXP-018-*`.
