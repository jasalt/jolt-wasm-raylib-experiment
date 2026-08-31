# Development

Run the Phase 0 witness from the pinned shell:

```sh
nix develop -c ./scripts/bootstrap
nix develop -c ./scripts/test-native
nix develop -c ./scripts/nrepl-smoke
```

Each script fails fast and writes ignored evidence beneath `artifacts/`.

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
