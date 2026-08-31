# Development

Run the Phase 0 witness from the pinned shell:

```sh
nix develop -c ./scripts/bootstrap
nix develop -c ./scripts/test-native
nix develop -c ./scripts/nrepl-smoke
```

Each script fails fast and writes ignored evidence beneath `artifacts/`.
