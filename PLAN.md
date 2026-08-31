# Jolt + Chez WebAssembly + Raylib experiment plan

**Status:** initial research specification, 2026-08-31. Nothing described as a
proposed experiment is evidence that it works. Runtime behavior becomes
**observed** only when a reproducible experiment records exact revisions,
commands, output, and artifacts.

## 1. Objective

Determine whether a Jolt application can run through Chez Scheme's Emscripten
WebAssembly build and drive Raylib in a web browser with a useful REPL-driven
development loop.

The smallest successful result is not “a Wasm file exists.” It is:

1. Jolt application code is compiled to Scheme by Jolt;
2. Chez executes that code with its portable-bytecode interpreter compiled to
   WebAssembly by Emscripten;
3. Jolt calls a deliberately narrow, ABI-verified Raylib facade;
4. Raylib renders a recognizable frame into an HTML canvas; and
5. browser automation opens the served page, observes readiness, captures the
   canvas/page, and a vision-capable coding agent inspects the screenshot.

The development-quality target additionally keeps application state alive while
a debug-only evaluation path replaces a Var-backed function and changes a later
browser frame without rebuilding the Wasm module or reloading the page.

A reduced and reproducible blocker is a valid result. Do not substitute Gambit's
JavaScript backend, ClojureScript, a JVM runtime, or JavaScript-authored drawing
and describe that as Chez WebAssembly success.

## 2. Terminology and evidence boundary

“Chez Wasm compilation” in this project means the upstream Chez Emscripten path:
Chez's C kernel and portable-bytecode interpreter are compiled to WebAssembly,
while Scheme/Jolt program code is cross-compiled to a `pb`-family Chez boot
file and preloaded into the Emscripten output. Chez upstream explicitly labels
this target “WebAssembly via Emscripten (bytecode interpreter only).” It is not a
new Chez backend that lowers each Scheme form directly to Wasm instructions.

Keep these claims separate:

- **Chez/Wasm:** a Scheme witness boots and runs under Node and then a browser.
- **Jolt/Wasm:** portable Jolt code boots through that exact Chez target.
- **Raylib/Web:** plain C Raylib renders with its `PLATFORM_WEB` backend.
- **Chez-to-Raylib:** Chez portable bytecode calls a statically linked C facade.
- **Jolt-to-Raylib:** Jolt `jolt.ffi` calls that facade and owns frame state.
- **Browser validation:** a real browser renders and automation captures the
  visible result.
- **Live development:** a running browser instance observes a redefinition.

Passing a later layer does not erase a missing proof at an earlier layer.

## 3. Sources consulted and provisional source baseline

The plan is based on the following upstream material and local sibling
checkouts. Implementation must pin exact revisions in project configuration and
record them again in every experiment; the hashes below are planning-time
observations, not permanent promises.

| Project | Planning-time revision | Role |
| --- | --- | --- |
| Jolt (`../jolt`) | `447b874d06066d15fee187200fabaf410f4ff5b6` | compiler, Chez host, portable Scheme adapter contract |
| Raylib-Jolt (`../raylib-jlt`) | `7685ed987aa2dc27ab2499f2804bb28b793d6638` | binding and example patterns; not Wasm proof |
| Chez Scheme | `7fadeee45fcc0135b17f5c1a926157004f898339` | upstream `--emscripten` and `pb` implementation |
| Raylib | `9f3cadf1e618f125bd9b282c7759f8cb26ce17fc` | authoritative `PLATFORM_WEB` implementation |

Relevant facts that must be tested rather than extrapolated:

- Chez's `BUILDING` documents `./configure --emscripten`, `--threads`,
  `--pbarch`, `--emboot`, and `--empetite`.
- Jolt currently requires a threaded Chez 10.x in its normal launcher and its
  Chez backend is the flagship, fully capable backend.
- Jolt's portable Scheme layer defines explicit degradations for a future
  threadless browser target, but `host/scheme-adapter/THREADS.md` says those
  implementations do not yet exist.
- Chez issue 876 states that portable bytecode supports only the foreign-call
  prototypes enumerated by `define-pb-prototypes`; additional C functions may
  need `Sforeign_symbol` registration and reduced wrappers.
- Raylib's web guidance requires Emscripten and recommends a browser-owned
  frame callback instead of a blocking `while (!WindowShouldClose())` loop.
- Emscripten pthread builds require `-pthread`, SharedArrayBuffer, and COOP/COEP
  headers. A threaded and non-threaded build cannot be one universal binary.
- `raylib-jlt` assumes dynamically discoverable desktop libraries and contains
  many signatures and aggregate-ABI paths. It is a design/source reference,
  not something to load wholesale before the Wasm FFI boundary is proved.

When documentation and implementation differ, prefer pinned Chez, Jolt,
Raylib, and Raylib-Jolt source plus reduced experiments. Never infer behavior
from JVM Clojure.

## 4. Non-negotiable working rules

1. Follow `AGENTS.md` and the referenced Jolt guidance before changing code.
2. Use Beads as the only live task tracker. This plan is a specification, not a
   status board, and must not accumulate checkboxes or informal TODOs.
3. Claim one ready bead at a time. New scope gets a new bead and dependencies.
4. Begin every technical uncertainty with the smallest observable experiment.
5. Use a native Jolt nREPL for pure application code before rebuilding Wasm.
6. Preserve exact commands, versions, logs, and screenshots for both success
   and failure.
7. Browser-rendering claims require browser automation and screenshots. A
   process exit, console message, generated PNG inside Emscripten's virtual
   filesystem, or uninspected screenshot is insufficient.
8. Visual gates must be completed by an agent with vision capability. Record
   what is visibly present, not merely that the image file is nonempty.
9. Keep all Raylib and Emscripten callbacks on their proven owner thread. Do not
   call drawing, input, resource, or lifecycle FFI from an evaluator worker.
10. Do not patch Jolt, Chez, Raylib, or Raylib-Jolt until a reduced witness
    locates the failure. Carry patches as named project files with upstream
    revision, rationale, and a no-patch control result.
11. Make small atomic Git commits after validated increments and push them.
    Keep the corresponding Beads/Dolt state synchronized. Never bundle
    unrelated evidence or generated caches into a source commit.
12. Do not claim a test passed through a pipeline that masks an exit status.
13. Do not commit credentials, machine-local paths, mutable SDK installs,
    browser profiles, Emscripten caches, or unreviewed generated binaries.

## 5. Repository and documentation shape

The intended structure is:

```text
jolt-wasm-raylib/
├── AGENTS.md                    # self-contained coding-agent rules
├── README.md                    # concise human-facing overview and entry links
├── PLAN.md                      # this governing experiment specification
├── REPORT.md                    # final evidence-based assessment
├── deps.edn                    # Jolt source roots/dependencies where applicable
├── flake.nix
├── flake.lock                   # pinned build/tool boundary
├── pins.edn                    # upstream revisions and source hashes
├── docs/
│   ├── README.md               # topic index
│   ├── ARCHITECTURE.md         # architecture actually observed
│   ├── DEVELOPMENT.md          # repeatable REPL/build/serve/browser workflows
│   ├── GOTCHAS.md              # evidence-backed integration traps
│   ├── WASM-TOOLCHAIN.md       # Chez/Emscripten boot and link procedure
│   └── adr/
│       ├── README.md
│       └── NNNN-*.md
├── src/
│   ├── README.md               # overall source architecture
│   ├── app/
│   │   └── README.md           # portable Jolt state/update/view concerns
│   ├── raylib/
│   │   └── README.md           # Jolt facade and owner-thread rendering concerns
│   ├── native/
│   │   └── README.md           # C registration, scheduler, and ABI facade
│   └── web/
│       └── README.md           # HTML shell, status surface, and JS debug bridge
├── test/
│   ├── README.md
│   ├── app/
│   ├── native/
│   └── browser/
├── scripts/
│   ├── bootstrap
│   ├── chez-wasm-build
│   ├── jolt-boot-build
│   ├── raylib-web-build
│   ├── web-build
│   ├── web-serve
│   ├── browser-smoke
│   └── verify
├── experiments/
│   ├── README.md
│   └── EXP-NNN-*/
│       ├── README.md
│       ├── commands.sh
│       ├── environment.txt
│       └── evidence/
└── artifacts/
    ├── logs/
    ├── reports/
    └── screenshots/
```

Create a README in `src/` before adding source. Every source subdirectory must
have a narrower README before or with its first implementation file. Use fenced
D2 diagrams where structure or ownership is clearer visually than in prose.
Do not duplicate the plan into every README:

- `README.md` answers what the project is, current evidence level, and how a
  human starts.
- `AGENTS.md` governs agent process and points to this plan.
- `PLAN.md` defines proof order and acceptance criteria.
- `docs/ARCHITECTURE.md` records only demonstrated architecture.
- `docs/DEVELOPMENT.md` records commands that have actually worked.
- `docs/GOTCHAS.md` records observed traps and their evidence.
- `experiments/` retains reduced reproductions.
- `REPORT.md` gives the final graded conclusion.
- Beads contains changing task state and durable discoveries.

Generated `.js`, `.wasm`, `.data`, boot files, build directories, browser
profiles, and package caches are ignored by default. Commit a generated artifact
only when it is small, necessary evidence, reproducibly generated, and explicitly
listed in an experiment's artifact manifest with a hash.

## 6. Proposed architecture

The primary topology is one Emscripten module containing Chez's portable
bytecode runtime, the selected Jolt boot payload, the narrow C facade, and
Raylib's web static archive.

```d2
browser: {
  label: "Browser"
  canvas: "HTML canvas / WebGL"
  raf: "requestAnimationFrame"
  status: "DOM readiness + diagnostics"
  automation: "browser automation + screenshots"
}

module: {
  label: "One Emscripten module"
  scheduler: "C frame scheduler"
  chez: "Chez pb32l/tpb32l interpreter"
  boot: "Jolt + application boot payload"
  facade: "registered C ABI facade"
  raylib: "Raylib PLATFORM_WEB"

  scheduler -> chez: "enter one Jolt frame"
  chez -> boot: "execute compiled Jolt"
  boot -> facade: "jolt.ffi / supported pb prototypes"
  facade -> raylib: "native C calls"
}

browser.raf -> module.scheduler
module.raylib -> browser.canvas
module.scheduler -> browser.status: "readiness/diagnostics"
browser.automation -> browser.status
browser.automation -> browser.canvas: "input + screenshot"
```

### 6.1 Browser-owned frame scheduling

Do not initially compile the desktop recursive `while` loop with Asyncify. The
first design uses `emscripten_set_main_loop(..., 0, ...)` or the equivalent
Raylib/Emscripten callback so the browser owns scheduling. A small C callback
enters one persistent Jolt frame function and returns promptly. Jolt owns model,
update, and drawing decisions; C owns only runtime initialization, static symbol
registration, frame callback scheduling, and orderly shutdown.

This split is not a claim that Chez re-entry works. Prove it first with a Scheme
counter callback, then Jolt, then Raylib. Record the exact Chez C-API root and
procedure lifetime strategy; never retain an unregistered moving Scheme object
in a C global.

### 6.2 Thread variants

The primary first attempt is the smallest stock configuration that satisfies
Jolt's current threaded-Chez requirement, likely `tpb32l` built with Emscripten
pthreads. It must be tested under Node before browser rendering. Browser serving
must emit at least:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Do not assume `tpb32l` is viable on the browser main thread. Measure startup,
thread creation, waits, Raylib proxying, and shutdown. Evaluate
`PROXY_TO_PTHREAD` only in its own experiment because canvas/DOM work may be
proxied and owner-thread assumptions change.

If the threaded target is blocked, the fallback is a separate `pb32l` build and
a deliberate Jolt thread-capability degradation following
`../jolt/host/scheme-adapter/THREADS.md`. That is a Jolt porting project, not a
compiler flag. It must preserve synchronous/eager/honest behavior and add
known-divergence evidence. Never silently compile out threads or busy-wait on
the browser UI thread.

### 6.3 Static FFI and symbol registration

Do not depend on browser `dlopen`. Raylib and the project facade are linked into
the Emscripten module. The startup C code registers only the required facade
symbols with Chez using the pinned supported mechanism (`Sforeign_symbol` is
the planning candidate). Jolt resolves those symbols through its process/native
FFI path.

Before writing the facade, produce a machine-readable matrix for every binding:

```text
Jolt declaration
→ emitted Chez foreign type list
→ Chez pb prototype id
→ C facade prototype
→ Raylib call
→ ownership/lifetime
→ test witness
```

Start with no-argument, integer, unsigned integer, pointer, and string-shaped
calls already supported by stock Chez portable bytecode. Prefer a data-oriented
command/config pointer over adding many arbitrary portable-bytecode prototypes.
If one missing prototype remains after reduction, compare:

1. a C wrapper using an existing prototype;
2. a compact command buffer; and
3. a minimal Chez `define-pb-prototypes`/`pb_call` extension.

Choose an upstream Chez change only if wrappers would materially damage the API
or correctness. Do not add `libffi-emscripten` before the stock prototype subset
and C wrapper route are measured.

### 6.4 Raylib-Jolt use

Use `../raylib-jlt` for:

- naming and color packing conventions;
- ergonomic keyword-argument wrapper design;
- simple examples and pure drawing functions;
- timed exit/readiness ideas;
- desktop nREPL owner-thread lessons; and
- attribution to the matching Raylib examples.

Do not compile all bindings into the first Wasm payload. Create a minimal
project-owned facade for window/canvas initialization, drawing begin/end,
background clear, text or primitive drawing, frame time, and basic input. Keep
portable app code independent from that facade. Later assess whether a Wasm
platform layer belongs upstream in Raylib-Jolt.

## 7. REPL-driven development contract

REPL-driven work has two levels.

### 7.1 Mandatory native loop

Start a normal Jolt nREPL in this project for pure Jolt code:

```sh
jolt nrepl-server
```

Develop model transitions, animation state, command generation, layout, and
portable tests by evaluating individual forms. Long-lived state belongs in
`defonce` cells where appropriate, and frame code must call live Vars rather
than startup-captured function values. Turn each successful REPL observation
into an automated native test before crossing into Wasm.

No Raylib FFI may execute on a native nREPL worker unless a desktop experiment
has explicitly transferred it to the Raylib owner thread. The browser build is
a different process and does not receive nREPL operations over TCP.

### 7.2 Development-quality browser loop

A debug-only browser bridge may expose an Emscripten export that accepts source
text or an operation request. Browser JavaScript queues the request; the proven
Jolt/Raylib owner processes at most a bounded amount between frames. A worker or
JavaScript callback must never enter drawing FFI concurrently.

The desired observation is:

```text
edit a pure Var-backed frame/layout function
→ evaluate through native nREPL for fast local feedback
→ submit the same definition through the debug browser bridge
→ owner applies it at a frame boundary
→ next frames visibly change
→ browser automation captures before/after screenshots
```

The bridge must be loopback/development-only in the local server, absent from a
release build, bounded, diagnostic, and covered by tests. If Jolt's compiler is
excluded with `--empetite`, runtime eval is unavailable by design; report that
as a build-profile tradeoff rather than claiming live redefinition.

A full browser nREPL protocol is optional and must not precede the bounded eval
proof. WebSocket transport, CIDER middleware, remote exposure, authentication,
and production eval are non-goals.

## 8. Reproducible environment

Use a pinned Nix flake as the default tool boundary. It should supply, at exact
versions where practical:

- Jolt and a source checkout at the selected revision;
- Chez source and native host Chez needed to cross-build target boot files;
- Emscripten SDK (`emcc`, `emar`, Node, and associated sysroot);
- Raylib source;
- CMake, Ninja, GNU Make, a native C compiler, Python, Git, and Babashka;
- clj-kondo and clojure-lsp for source checks;
- Playwright or the selected browser automation library plus a pinned Chromium;
- D2 for optional diagram rendering checks;
- image metadata/diff tools; and
- Beads.

`scripts/bootstrap` must be non-mutating and write
`artifacts/reports/environment.txt` with at least:

```text
UTC timestamp
uname and architecture
Nix version and flake lock revision
Jolt version and Git revision
Chez native version and Git revision
Chez target machine type
Raylib and Raylib-Jolt revisions
Emscripten, clang, wasm-ld, Node, Python versions
browser name and version
COOP/COEP server configuration
DISPLAY/WAYLAND indicators where relevant
Git status
```

Do not rely on a globally activated mutable `emsdk`. Caches may accelerate a
build but must not be required for correctness.

## 9. Experiment method and record format

Every uncertainty gets an `experiments/EXP-NNN-short-name/` directory. Its
`README.md` uses this structure:

```markdown
# EXP-NNN — title

## Problem
## Hypothesis
## Environment
## Minimal reproduction
## Expected
## Actual
## Investigation
## Result
## Suspected layer
## Workaround or next experiment
## Upstream suitability
## Artifacts and hashes
```

`commands.sh` must be fail-fast and runnable from the repository root. Keep raw
logs under the experiment or `artifacts/logs/EXP-NNN/` according to size. The
README links, hashes, and interprets them. Record failures verbatim before
trying a workaround.

Use these failure categories:

- `ENVIRONMENT`
- `CHEZ_EMSCRIPTEN`
- `CHEZ_PB_ABI`
- `JOLT_CHEZ_HOST`
- `JOLT_THREAD_CAPABILITY`
- `JOLT_FFI`
- `RAYLIB_WEB`
- `EMSCRIPTEN_LINK`
- `BROWSER_SECURITY`
- `BROWSER_RENDERING`
- `AUTOMATION`
- `PROJECT_CODE`
- `UNKNOWN`

A workaround does not change the category of the original failure. An upstream
patch needs a no-patch control, minimal patch, exact upstream base, focused
test, and explanation of why the project facade cannot reasonably own it.

## 10. Proof order

Do not skip a phase because a larger combined build happens to work.

### Phase 0 — repository, pins, and diagnostics

Create the documented repository shape, ignore rules, Nix shell, pin registry,
bootstrap diagnostics, experiment template, source README hierarchy, and basic
quality gates. Verify the native Jolt nREPL with a pure arithmetic/state witness.

**Acceptance:** a clean clone enters the shell, prints all pinned tool versions,
runs one native Jolt test, and starts a loopback nREPL.

### Phase 1 — stock Chez Emscripten witness

#### EXP-001: portable bytecode under Node

Build unmodified pinned Chez with `--emscripten`, first in the simplest upstream
configuration. Cross-compile a boot file whose `scheme-start` prints a token,
performs allocation/GC, exercises exact and inexact arithmetic, and exits. Run
with upstream `make run`/Node. Repeat for the candidate `tpb32l` configuration
needed by Jolt.

**Acceptance:** Node output and exit status prove the exact boot payload ran;
artifacts identify machine type and pointer width.

#### EXP-002: portable bytecode in a browser

Serve the unchanged Chez witness, open it with browser automation, assert a DOM
or console completion token, and capture a screenshot. For pthreads, prove
`crossOriginIsolated === true` and retain response-header evidence.

**Acceptance:** a real browser completes the witness with no uncaught page,
console, or worker errors.

### Phase 2 — Jolt compatibility before Emscripten

#### EXP-003: Jolt on native portable-bytecode Chez

Run the smallest Jolt host/kernel and selected conformance forms on a native
`tpb32l` Chez before involving Wasm. Inventory failures by adapter capability,
32-bit assumption, foreign prototype, machine-type parsing, subprocess,
filesystem, and thread semantics.

Begin with reader/value/collection/eval witnesses, not the entire suite. Expand
to the relevant Jolt corpus only after the kernel loads.

**Acceptance:** a documented subset of Jolt forms compiles and evaluates on the
same Chez target machine family intended for Emscripten, or a reduced blocker
identifies the first incompatible Jolt/target boundary.

### Phase 3 — Jolt boot payload under Node

#### EXP-004: minimal Jolt application boot

Cross-mint a target-compatible Jolt boot payload on the native host, configure
Chez with `--emboot`, and execute a pure Jolt application under Node. The
application prints canonical EDN for fixed inputs and an explicit completion
token. Compare results with native Jolt fixtures.

Do not add Raylib, browser APIs, or a custom FFI prototype here.

**Acceptance:** canonical outputs match native Jolt and the process exits
cleanly under allocation pressure.

### Phase 4 — plain C Raylib web baseline

#### EXP-005: browser canvas without Chez

Build pinned Raylib for `PLATFORM_WEB` with Emscripten and a tiny C application
using the recommended browser main loop. Render a high-contrast diagnostic
frame containing fixed geometry, text, and a frame counter. Expose readiness in
the DOM or an exported status function.

Drive it exclusively with browser automation: open the local HTTP URL, wait for
readiness, capture a full-page screenshot and a canvas-only screenshot, inspect
the images with vision, and retain browser console/network logs.

**Acceptance:** screenshots visibly contain all specified elements at the
expected relative positions and colors; no WebGL or shader error appears.

### Phase 5 — Chez-to-C static FFI

#### EXP-006: registered scalar facade under Node

Statically link a tiny C library into Chez's Emscripten output, register its
symbols, and call it from target Scheme using only stock supported portable
bytecode prototypes. Cover no-arg, integer, unsigned, pointer, UTF-8 string, and
one foreign-memory round trip as required by the planned facade.

**Acceptance:** every call has an independent expected value and ownership test;
unsupported shapes fail at build time or with a clear reduced error.

#### EXP-007: Chez drives one Raylib frame

Combine the stock Chez browser witness and the plain C Raylib baseline. Scheme
selects colors/text/state and calls the minimal facade; C schedules a finite
number of callbacks. Browser automation captures and vision-inspects the frame.

**Acceptance:** changing a Scheme literal changes the visible frame while the C
facade remains unchanged.

### Phase 6 — Jolt in the browser without graphics

#### EXP-008: pure Jolt browser witness

Run the EXP-004 Jolt payload in the browser. Publish startup, result, and failure
state to a stable DOM diagnostics element instead of relying only on console
text. Exercise Unicode, persistent collections, atoms, exceptions, and repeated
frame-like calls.

**Acceptance:** browser and native fixture outputs match; automation reports no
uncaught exception or worker failure.

### Phase 7 — first Jolt-driven Raylib frame

#### EXP-009: minimal binding subset

Implement the smallest project-owned Jolt facade against the verified C ABI.
Compile only declarations needed by the diagnostic scene. Verify every emitted
Chez FFI signature against the EXP-006 matrix.

#### EXP-010: first frame

Jolt initializes app state, emits the drawing choices, and calls Raylib for one
recognizable frame. Browser automation waits on a Jolt-origin readiness marker,
captures page and canvas screenshots, and a vision-capable agent records visible
content.

**First-frame acceptance criterion:**

- the page identifies the exact Jolt/Chez/Raylib revisions;
- the canvas is nonblank and has the expected dimensions;
- a distinctive background, at least two colored primitives, and legible text
  are visible;
- one visible value originates from mutable Jolt state;
- the browser console has no uncaught exception, Wasm trap, WebGL error, or
  missing asset;
- Jolt and the facade emit matching frame/ready diagnostics; and
- screenshots and logs are retained with hashes.

### Phase 8 — persistent browser-owned loop and input

#### EXP-011: requestAnimationFrame lifecycle

Keep Jolt model state alive across browser callbacks. Measure owner identity,
frame count, update/draw duration, allocation, and shutdown behavior. Avoid a
blocking Jolt loop and avoid Asyncify unless a separate experiment justifies it.

#### EXP-012: input and resize

Use browser automation to send pointer and keyboard events, then prove Jolt
state and visible output change. Resize the viewport/canvas and verify layout
adapts. Record focus requirements and browser-specific event behavior.

**Acceptance:** one process/module survives at least 600 frames, automated input
causes deterministic state transitions, and screenshots visibly show the before
and after states.

### Phase 9 — live browser redefinition

#### EXP-013: bounded debug evaluation bridge

Retain the Jolt compiler in a debug profile, submit a pure `defn` replacement,
and apply it on the owner at a frame boundary. Prove dynamic Var lookup by also
keeping a startup-captured function control that remains stale.

Browser automation captures before/after screenshots from the same page and
module instance. Record module/process identity, state continuity, owner
identity, eval result, and frame numbers.

**Acceptance:** the live Var-backed path changes visibly without page reload or
Wasm rebuild, state survives, the stale control does not change, and release
output contains no eval export.

### Phase 10 — stress, performance, and capability boundaries

Run focused experiments for:

- startup time and boot payload size;
- fixed versus growing Wasm memory;
- 10,000 update-only calls and at least 10 minutes of rendering;
- allocation and explicit GC pressure;
- tab background/foreground and animation pause/resume;
- WebGL context loss/restoration where automation permits;
- repeated page/module initialization and shutdown;
- Unicode text crossing Jolt → Chez → C;
- input bursts and bounded debug queue overflow;
- threaded worker creation and shutdown;
- browser refresh/cache invalidation; and
- debug/full-compiler versus petite/release bundle size.

Performance observations must report browser, hardware, viewport, build flags,
warmup, sample count, percentiles, dropped/slow frames, Wasm bytes, startup
milliseconds, and peak memory. Do not call a result “fast” without a declared
budget and comparison.

### Phase 11 — clean-room verification and report

`scripts/verify` starts from a clean generated state and runs fail-fast tiers:

1. source formatting/lint/static checks;
2. native portable tests;
3. Chez Node witness;
4. Jolt Node witness;
5. plain Raylib browser smoke;
6. Jolt/Raylib browser smoke;
7. automated input and visual captures;
8. debug redefinition, when supported; and
9. artifact/hash/report consistency.

It writes one log per tier and a summary distinguishing `PASS`, `FAIL`, and
`SKIP` with an explicit reason. A visual tier cannot be marked `PASS` until the
screenshot has been inspected by a vision-capable agent. Then write `REPORT.md`
with claims no broader than the evidence.

## 11. Browser automation and visual validation

Use a browser automation API, preferably Playwright with pinned Chromium. Shell
scripts may start the server and invoke the automation suite, but rendering
validation itself must use browser operations, not `curl` plus image existence.

The local test server must:

- bind loopback only;
- serve correct Wasm MIME types;
- emit COOP/COEP headers for the pthread build;
- disable caching or use content-hashed assets during development; and
- expose a health endpoint separately from application readiness.

Every browser smoke test must:

1. attach console, page-error, request-failure, and WebGL diagnostic capture;
2. navigate to the HTTP URL rather than `file://`;
3. wait for an explicit state such as `data-jolt-state="ready"`;
4. assert canvas width/height and nonzero rendered pixel variance;
5. perform the experiment's input or eval action;
6. capture full-page and canvas screenshots with deterministic viewport/device
   scale;
7. store browser/version/build metadata and screenshot hashes; and
8. have a vision-capable agent inspect semantic content and write a concise
   observation in the experiment README.

Pixel statistics and image diffs are useful regression checks, but they do not
replace semantic inspection. Avoid brittle whole-image equality for text and
GPU rasterization; use regions, tolerances, stable diagnostic geometry, and
human/vision interpretation.

## 12. Testing pyramid

### Tier 1 — pure native Jolt

- reducers and model transitions;
- deterministic layout/command generation;
- Unicode and serialization;
- queue bounds and lifecycle state machines.

### Tier 2 — Chez target witnesses

- `pb32l`/`tpb32l` boot;
- arithmetic, allocation, GC, exceptions, and repeated re-entry;
- supported foreign-call prototype matrix.

### Tier 3 — native C/ABI

- C facade unit tests;
- command/config layout sizes and offsets;
- string and pointer ownership;
- static symbol registration.

### Tier 4 — Node Wasm

- Chez boot;
- pure Jolt fixture parity;
- target diagnostics without browser/Raylib variability.

### Tier 5 — browser structural

- headers, readiness, worker startup, console cleanliness;
- canvas dimensions, input delivery, lifecycle, and release export audit.

### Tier 6 — browser visual

- automated screenshots;
- stable pixel/region checks;
- vision inspection of first frame, input change, resize, and live redefinition.

A Tier 6 success never compensates for incorrect Tier 1 semantics or an
unverified Tier 3 ABI.

## 13. Security, release, and licensing boundaries

- Bind development servers to `127.0.0.1`.
- Never expose arbitrary eval from release output.
- Audit generated Emscripten exports and symbols for debug-only entry points.
- Treat browser source maps and embedded source as release decisions.
- Use a restrictive Content Security Policy compatible with the selected
  Emscripten output and document any `unsafe-eval` requirement.
- Record third-party licenses and source attribution. Raylib and Raylib-Jolt use
  zlib/libpng terms; Chez Scheme and Jolt have their own licenses. Do not copy
  examples or bindings without preserving notices.
- Do not commit private browser data or tokens in console/network captures.

## 14. Atomic commit and synchronization discipline

A normal engineering increment is:

```text
claim one bead
→ run/record the smallest experiment
→ add focused implementation or documentation
→ run relevant gates
→ inspect generated visual evidence when applicable
→ update/close the bead with exact evidence
→ commit source atomically
→ commit Beads/Dolt state
→ pull/rebase safely
→ push source and Beads/Dolt refs
→ verify clean synchronized status
```

Commit examples:

```text
chore: pin initial wasm toolchain
experiment: prove Chez tpb32l under Node
experiment: register scalar FFI facade
feat: render first Jolt-driven browser frame
experiment: prove live browser redefinition
```

Do not rewrite published experiment history. A corrected conclusion gets a new
commit and, when material, a new experiment or superseding ADR.

## 15. Success levels

### W0 — blocked environment

The pinned shell or stock Chez Emscripten build cannot be reproduced. Preserve
the blocker and exact host/tool evidence.

### W1 — Chez in Wasm

Pinned Chez portable bytecode runs under Node and a real browser.

### W2 — Jolt in Wasm

A pure Jolt payload runs under the same Chez Wasm target and matches native
fixtures.

### W3 — static FFI and plain Raylib

The stock Chez portable-bytecode FFI reaches a registered facade, and the same
browser/toolchain renders the plain C Raylib baseline.

### W4 — Jolt first frame

Jolt visibly drives one Raylib browser frame and passes the first-frame
acceptance criterion.

### W5 — persistent interactive host

A browser-owned callback loop preserves Jolt state, processes automated input,
and survives stress without owner-thread or GC failure.

### W6 — development-quality experiment

Native nREPL is documented, debug browser redefinition visibly works without a
reload, browser automation and clean-room verification pass, release output has
no eval bridge, and architecture/performance/limitations are documented.

Reaching W4 is a successful feasibility proof. W6 is required before describing
the project as a useful REPL-driven browser workflow.

## 16. Initial Beads dependency graph

Create these as Beads after this plan exists; generated IDs, not titles in this
section, are authoritative for task state.

1. **Epic: prove Jolt + Chez Wasm + Raylib browser feasibility**.
2. **Scaffold repository, pins, docs hierarchy, and diagnostics**.
3. **Prove stock Chez portable bytecode under Node** — depends on 2.
4. **Prove stock Chez portable bytecode in automated browser** — depends on 3.
5. **Audit Jolt against native `tpb32l` Chez** — depends on 3.
6. **Run pure Jolt boot payload under Node Wasm** — depends on 5.
7. **Prove plain C Raylib web rendering with automated screenshots** — depends
   on 2.
8. **Prove static registered Chez portable-bytecode FFI facade** — depends on 3.
9. **Render one Chez-driven Raylib browser frame** — depends on 4, 7, and 8.
10. **Run pure Jolt payload in automated browser** — depends on 4 and 6.
11. **Implement and verify minimal Jolt Raylib facade** — depends on 8 and 10.
12. **Render and inspect first Jolt-driven Raylib frame** — depends on 9 and 11.
13. **Implement persistent browser-owned Jolt frame loop and input** — depends
    on 12.
14. **Prove debug-only live browser redefinition** — depends on 13.
15. **Run stress, size, clean-room verification, and final report** — depends
    on 13; the live-redefinition subsection depends on 14 but a W5 report may
    proceed if 14 is explicitly blocked.

The epic owns the outcome but does not replace child acceptance evidence.

## 17. Final report outline

`REPORT.md` should contain:

```markdown
# Jolt + Chez Wasm + Raylib report

## Executive conclusion and achieved success level
## Exact tested environment and revisions
## Chez portable-bytecode/Wasm architecture proven
## Jolt boot and capability profile
## Static FFI and symbol-registration design
## Raylib web integration and frame ownership
## Browser automation and visual evidence
## REPL-driven workflow
## Threading and browser-security constraints
## Correctness and conformance observations
## Startup, size, memory, and frame-time measurements
## What works
## What does not work
## Required project patches
## Upstream opportunities
## Security and release boundary
## Reproducible experiments
## Recommended next step
```

## 18. References

Consulted 2026-08-31; pin source revisions during implementation.

- Jolt repository guidance: `../jolt/llms.txt`
- Jolt documentation index: <https://jolt-lang.net/llms.txt>
- Jolt Scheme backends: <https://jolt-lang.net/docs/scheme-backends.html>
- Jolt REPL-driven development:
  <https://jolt-lang.net/docs/repl-driven-development.html>
- Jolt native interop: <https://jolt-lang.net/docs/native-interop.html>
- Jolt portable Scheme target contract:
  `../jolt/host/scheme-adapter/TARGET-CONTRACT.md`
- Jolt threadless-target design: `../jolt/host/scheme-adapter/THREADS.md`
- Chez Scheme repository and `BUILDING`:
  <https://github.com/cisco/ChezScheme>
- Chez Scheme Emscripten FFI discussion:
  <https://github.com/cisco/ChezScheme/issues/876>
- Raylib-Jolt repository: `../raylib-jlt` and
  <https://github.com/jlt-commons/raylib-jlt>
- Raylib repository: <https://github.com/raysan5/raylib>
- Raylib web guide:
  <https://github.com/raysan5/raylib/wiki/Working-for-Web-(HTML5)>
- Emscripten pthreads:
  <https://emscripten.org/docs/porting/pthreads.html>
- Emscripten browser main-loop API:
  <https://emscripten.org/docs/api_reference/emscripten.h.html#c.emscripten_set_main_loop>
- Experiment/documentation conventions: `../jolt-android/README.md`,
  `../jolt-android/AGENTS.md`, `../jolt-android/docs/PLAN.md`, and
  `../jolt-android/docs/RAYLIB-PLAN.md`
