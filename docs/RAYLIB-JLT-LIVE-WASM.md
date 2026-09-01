# Live Wasm demos (proposal)

> **Experimental.** The desktop examples in this repository are not bundled into
> this documentation site. Live browser artifacts are built by the separate
> Jolt/Chez/Raylib experiment and must pass its Chromium visual and input gates
> before being published here.

## Why an isolated origin

Threaded Emscripten builds require `Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp` to expose `SharedArrayBuffer`.
GitHub Pages cannot set those response headers per asset. A live demo therefore
**must not** be served from this site's own `/raylib-jlt/` origin.

The proposed deployment is:

```text
GitHub Pages documentation
  -> sandboxed iframe, explicit user activation
      -> versioned live-demo origin (COOP/COEP headers)
          -> Wasm + JS + data + worker assets
```

The iframe should use a release-specific URL, e.g.
`https://wasm.jlt-commons.org/raylib-jlt/<git-sha>/input-mouse/`, with a
same-origin `iframe` sandbox policy appropriate for its canvas and no access to
documentation cookies. The live origin must serve Wasm with `application/wasm`,
all worker/data assets with CORP-compatible headers, no cache during preview,
and a restrictive CSP. The document page retains its committed GIF as the
accessible no-JavaScript/failure fallback.

## Embed contract

Each published demo needs:

- a title and concise keyboard/mouse instructions;
- a focusable launch button, not automatic worker creation on page load;
- a fixed-aspect canvas iframe with an accessible fallback image/link;
- a status surface reporting loading, ready, failed, and the exact artifact
  revision;
- a postMessage-only, origin-checked optional resize/status channel; and
- release artifact hashes and a browser smoke report.

Do not embed the current desktop `jolt.ffi` raylib-jlt namespaces directly:
their dynamic-library ABI and owner loop differ from the browser static façade.
Port only examples whose required API has an explicit browser command/ABI
matrix and visual/input evidence.

## First candidates

The demonstrated scalar browser façade maps most closely to these examples:

1. `basic-window` — static scene and readiness;
2. `input-mouse` — pointer coordinates visibly move an object; and
3. `input-keys` — keyboard state visibly moves an object.

A release candidate needs independent screenshots for all three and browser
input automation before it is added to the gallery. Until then, GIF previews
remain the public documentation.
