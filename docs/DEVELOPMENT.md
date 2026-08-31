# Development

Run the Phase 0 witness from the pinned shell:

```sh
nix develop -c ./scripts/bootstrap
nix develop -c ./scripts/test-native
nix develop -c ./scripts/nrepl-smoke
```

Each script fails fast and writes ignored evidence beneath `artifacts/`.

## Chez and Raylib browser witnesses

```sh
nix develop -c env CHEZ_REBUILD=0 ./scripts/chez-browser-smoke
nix develop -c env SCENE=green ./experiments/EXP-007-chez-raylib/commands.sh
nix develop -c env SCENE=green ./experiments/EXP-007-chez-raylib/browser-smoke
```

EXP-007 performs a full Chez rebuild. Build `SCENE=red` separately to reproduce
the visible Scheme-literal control. See its README for hashes and ownership.

The genuine Jolt boundary is reproducible after EXP-004/006 artifacts exist:

```sh
nix develop -c ./experiments/EXP-008-jolt-browser/commands.sh
```

It currently fails intentionally at the retained `make-mutex` boundary; it is
not a passing browser command.

## Plain Raylib browser baseline

The EXP-005 plain-C Raylib baseline uses a browser-owned Emscripten main loop
and real Chromium automation:

```sh
nix develop -c ./scripts/browser-smoke
```

It rebuilds the pinned Raylib `PLATFORM_WEB` archive, serves loopback HTTP with
COOP/COEP headers, waits for a DOM readiness marker, captures page/canvas PNGs,
and fails on page errors or failed requests. See
[`EXP-005-raylib-web`](../experiments/EXP-005-raylib-web/README.md) for observed
results and artifact hashes.
