# EXP-014 Plan — Threaded Jolt on Chez `tpb32l` Emscripten

**Status:** proposed continuation experiment, 2026-08-31.

**Experiment directory:** `experiments/EXP-014-jolt-tpb32l-emscripten/`

**Primary question:** Can the exact pinned Jolt runtime that fails on non-threaded Chez `pb` initialize and execute unchanged when the pinned Chez revision is given a generated threaded portable-bytecode target (`tpb32l`) and compiled to WebAssembly with Emscripten pthreads?

**Secondary question:** If the full threaded build succeeds, can the same Jolt application payload run with Chez configured using `--empetite`, omitting `scheme.boot` while retaining the threaded Petite runtime and precompiled Jolt application boot?

This experiment exists specifically to test the strongest remaining alternative to implementing Jolt's threadless browser adapter.

It must not be treated as a Raylib experiment yet. Raylib, Jolt FFI, frame scheduling, input, persistent rendering, and browser live redefinition remain downstream work.

---

## 1. Context

The existing repository has demonstrated:

* pinned Chez portable bytecode under Node and Chromium;
* pinned Raylib rendering under Chromium;
* static C symbol registration into the Chez Emscripten module;
* no-argument and signed `integer-32` Chez → C calls;
* Scheme-controlled visible Raylib output through a narrow static facade;
* exact-host Jolt compiler emission of the full Scheme payload;
* recompilation of that payload into a genuine `pb` boot; and
* failure of that genuine Jolt boot before application startup at Jolt's first top-level `make-mutex`.

EXP-008 classified the reduced blocker as `JOLT_THREADLESS_ADAPTER`.

That classification is valid for the tested non-threaded `pb` target, but it does not yet prove that a threadless Jolt implementation is required for WebAssembly.

Pinned Chez documents an Emscripten target family in which:

```text
--emscripten
--threads
--pbarch
```

select a threaded portable-bytecode Emscripten target, expected here to be `tpb32l`.

The earlier attempted threaded Emscripten configuration failed because the checked-out Chez `boot/` directory contained only `pb` boots. It did not test whether the target boots could first be generated with Chez's documented cross-boot machinery.

This experiment closes that gap.

---

## 2. Pinned source boundary

Do not upgrade dependencies as part of this experiment.

Start from the revisions already recorded by the project:

| Component             | Revision / tool                                       |
| --------------------- | ----------------------------------------------------- |
| Jolt                  | `447b874d06066d15fee187200fabaf410f4ff5b6`            |
| Chez Scheme           | `7fadeee45fcc0135b17f5c1a926157004f898339`            |
| Raylib                | `9f3cadf1e618f125bd9b282c7759f8cb26ce17fc`            |
| Raylib-Jolt reference | `7685ed987aa2dc27ab2499f2804bb28b793d6638`            |
| Emscripten            | locked Nix shell; previously observed `6.0.8-git`     |
| Browser               | project-pinned Chromium from the Nix/test environment |

Raylib revisions remain recorded for repository consistency but Raylib is not linked or executed in this experiment.

If the exact pinned Chez revision contains a reproducible defect that prevents the documented `tpb32l` procedure, first reduce it against that revision. Do not silently move to Chez `main`.

An upstream revision comparison may be created only as a later diagnostic experiment.

---

## 3. Required reading before implementation

The coding agent must read, in this order:

1. repository `AGENTS.md`;
2. repository root `PLAN.md`;
3. repository `REPORT.md`;
4. `experiments/EXP-003-jolt-tpb32l-chez/README.md`;
5. `experiments/EXP-004-jolt-node/README.md`;
6. `experiments/EXP-006-chez-static-ffi/README.md`;
7. `experiments/EXP-008-jolt-browser/README.md`;
8. pinned Chez `BUILDING`, especially:

   * Emscripten;
   * ways to obtain boot files;
   * cross compiling Scheme programs;
   * `--threads`;
   * `--pbarch`;
   * `--emboot`;
   * `--empetite`;
9. pinned Jolt:

   * `host/scheme-adapter/CONTRACT.txt`;
   * `host/scheme-adapter/TARGET-CONTRACT.md`;
   * `host/scheme-adapter/THREADS.md`;
10. the pinned Chez build/configuration implementation implicated by `bootquick`, `tpb32l`, and Emscripten configuration.

Do not rely on remembered Chez or Emscripten behavior where the pinned source can answer the question.

---

## 4. Hypothesis

The primary hypothesis is:

> The pinned Chez revision can generate `tpb32l` boot files from a suitable native host build, use those files to construct a genuine threaded Jolt `tpb32l` application boot, and build an Emscripten pthread module in which Jolt reaches the same application witness that currently remains unreachable on `pb`.

The browser sub-hypothesis is:

> Once served in a cross-origin-isolated page with a sufficient pthread worker configuration, the same threaded Jolt payload can initialize under Chromium without falling back to threadless Jolt semantics.

The Petite sub-hypothesis is:

> After the full threaded build works, `--empetite` can remove Chez's compiler boot while retaining enough Petite runtime functionality to load and execute the precompiled Jolt application boot.

These are hypotheses only.

---

## 5. Explicit non-goals

Do not broaden EXP-014 into any of the following:

* implementing Jolt's documented threadless semantics;
* changing `fork-thread`, mutex, condition, future, agent, or STM semantics;
* linking Raylib;
* invoking Jolt FFI;
* extending Chez portable-bytecode FFI prototypes;
* adding `libffi-emscripten`;
* testing arbitrary pointers or aggregate ABIs;
* implementing a rendering loop;
* using Asyncify;
* implementing browser nREPL;
* implementing browser runtime `eval`;
* implementing hot reload or Var redefinition;
* testing input or canvas ownership;
* adding `PROXY_TO_PTHREAD`;
* adding OffscreenCanvas;
* optimizing download size;
* benchmarking Raylib performance;
* upgrading Chez, Jolt, Emscripten, or Raylib.

`PROXY_TO_PTHREAD` is especially excluded from this experiment.

If EXP-014 proves that Jolt runs under Node but browser-main-thread blocking prevents it from running in Chromium, create a separate experiment for `PROXY_TO_PTHREAD`. Do not hide that architectural change inside EXP-014.

---

## 6. Evidence ladder

EXP-014 must report the highest independently demonstrated level reached.

### T0 — target boots generated

The exact pinned Chez checkout successfully generates `tpb32l` target boot material.

Required evidence:

* command;
* exact host Chez machine type;
* exact requested target machine type;
* generated paths;
* relevant file hashes;
* exit status;
* target cross-compilation patch/path if produced.

This alone does not prove Emscripten threading.

### T1 — native `tpb32l` thread witness

A native or host-executable Chez setup for the generated `tpb32l` target executes a minimal threaded Scheme witness.

The witness must prove more than `(make-mutex)` returning.

It should exercise, using the pinned Chez primitives:

```text
make-mutex
mutex acquire/release
make-condition
fork-thread
cross-thread signal or equivalent deterministic completion
thread-local/thread-parameter behavior if cheaply observable
```

The exact minimal form must follow the actual Chez API.

The test must have deterministic completion rather than sleeping and assuming a worker ran.

### T2 — Emscripten `tpb32l` Chez witness under Node

The pinned Chez Emscripten runtime is configured as threaded portable bytecode and runs the reduced thread witness under Node.

Required evidence:

```text
machine type = tpb32l
threads actually enabled
worker/thread witness executed
completion token printed
exit status = 0
```

Do not infer `tpb32l` from filenames alone. Record a runtime or build-system observation that identifies the selected machine type.

### T3 — genuine Jolt boot under threaded Node Wasm

The exact Jolt-generated payload used to reduce EXP-008 is recompiled/minted for the `tpb32l` target and preloaded into the Emscripten module.

Jolt reaches the application witness that EXP-008 never reached.

Required evidence:

* no `make-mutex` startup failure;
* unmistakable Jolt-origin startup token;
* canonical application output;
* explicit completion token;
* native/Jolt expected output comparison;
* process exit status or deliberate clean runtime completion.

### T4 — threaded Chez witness in Chromium

Before introducing Jolt, the reduced threaded Chez witness boots in Chromium.

Required browser observations:

```text
crossOriginIsolated === true
typeof SharedArrayBuffer === "function"
threaded witness reaches completion
no uncaught page error
no worker startup failure
no failed required request
```

Retain response-header evidence.

### T5 — genuine Jolt browser witness

The same Jolt fixture from T3 executes in Chromium.

The browser must expose stable machine-readable diagnostics such as:

```text
runtime-started
jolt-started
fixture-result=<canonical value>
fixture-complete
```

Do not rely solely on stdout or browser console messages.

This level is the main success criterion.

### T6 — threaded Petite Jolt browser witness

Repeat the proven T5 configuration with `--empetite`.

The same precompiled Jolt application witness must execute and produce the same canonical result.

Record the resulting:

* `.js` size;
* `.wasm` size;
* `.data` size;
* boot/preload composition as observable from the build;
* startup result.

Size numbers are observations only, not optimization claims.

---

## 7. Experiment topology

The intended successful topology is:

```d2
host_build: {
  label: "Native build host"

  chez_native: "Pinned native Chez"
  bootquick: "bootquick / cross-boot machinery"
  tpb_boots: "tpb32l petite/scheme boots"
  jolt_compiler: "Pinned Jolt compiler"
  flat: "Jolt-emitted flat.ss"
  jolt_boot: "tpb32l Jolt application boot"

  chez_native -> bootquick
  bootquick -> tpb_boots
  jolt_compiler -> flat
  tpb_boots -> jolt_boot
  flat -> jolt_boot
}

emscripten: {
  label: "Pinned Emscripten build"

  chez_kernel: "Chez portable-bytecode kernel"
  pthreads: "Emscripten pthread support"
  preloads: "tpb32l runtime + Jolt application boot"
  module: "scheme.js + scheme.wasm + scheme.data"

  chez_kernel -> module
  pthreads -> module
  preloads -> module
}

browser: {
  label: "Chromium"

  isolation: "COOP / COEP"
  workers: "Web Workers / pthreads"
  jolt: "Jolt runtime"
  fixture: "pure Jolt witness"
  status: "DOM diagnostics"

  isolation -> workers
  workers -> jolt
  jolt -> fixture
  fixture -> status
}

host_build.jolt_boot -> emscripten.preloads
emscripten.module -> browser.jolt
```

No Raylib or canvas belongs in this graph.

---

## 8. Proposed experiment directory

Create:

```text
experiments/EXP-014-jolt-tpb32l-emscripten/
├── PLAN.md
├── README.md
├── commands.sh
├── witness-thread.ss
├── witness-app/
│   └── README.md
└── patches/
    └── README.md
```

Prefer existing repository build and browser helpers instead of duplicating them.

Only add experiment-local scripts when existing scripts cannot express the reduced experiment cleanly.

`README.md` must use the standard experiment headings:

```text
Problem
Hypothesis
Environment
Minimal reproduction
Expected
Actual
Investigation
Result
Suspected layer
Workaround or next experiment
Upstream suitability
Artifacts and hashes
```

At creation time, its `Actual` and `Result` sections must say that the experiment has not yet been run. Do not pre-fill expected success as observation.

`patches/README.md` should state that no patch is currently expected and document the patch discipline. Do not create an empty fake patch.

---

## 9. Work package A — establish controls

Before generating new target boots, rerun or reuse the minimum controls needed to prove that the working tree still matches the prior evidence boundary.

Record:

```sh
git status --short
git rev-parse HEAD
nix develop -c ./scripts/bootstrap
```

Verify the pinned source revisions.

Re-run the narrow EXP-008 failing control if practical:

```text
pb Jolt boot
→ reaches top-level Jolt startup
→ fails at make-mutex
```

The purpose is to ensure that later success is attributable to `tpb32l`, not unrelated workspace drift.

Do not spend time reproducing every earlier Raylib experiment.

### Acceptance

The current non-threaded failure is still reproducible or its previous immutable evidence is sufficient and the exact source/build boundary is unchanged.

---

## 10. Work package B — generate `tpb32l` boot files

Start with the documented Chez mechanism, provisionally:

```sh
make bootquick XM=tpb32l
```

or its equivalent:

```sh
zuo . bootquick tpb32l
```

The coding agent must inspect the pinned `BUILDING`, Makefile/Zuo implementation, and generated paths before finalizing the command.

Do not guess whether the native Chez build must be `pb`, `tpb64l`, or another machine type. Establish this from the pinned implementation and a reduced run.

Record:

* host build configuration;
* source revision;
* exact target machine type;
* exact command;
* generated boot paths;
* generated `xpatch` or equivalent;
* SHA-256 hashes;
* output of any target-identification command;
* failure output verbatim.

### Important distinction

The previous:

```text
No suitable machine type found in "./boot".
Available machine types:
  pb
```

must remain in project history.

Generating `tpb32l` boots is a new condition, not a reinterpretation of that earlier failure.

### Stop condition

If the exact pinned Chez revision cannot generate `tpb32l` boots using its documented machinery, stop before Jolt.

Reduce the failure to Chez alone and classify it `CHEZ_EMSCRIPTEN` or `ENVIRONMENT` as appropriate.

Do not patch Jolt.

---

## 11. Work package C — native threaded Chez control

Before involving Emscripten or Jolt, prove that the generated target boots represent a functioning threaded portable-bytecode configuration.

Create `witness-thread.ss`.

It must minimally prove:

1. runtime startup;
2. mutex creation;
3. mutex acquire/release;
4. worker/thread creation;
5. deterministic communication back to the creating thread;
6. clean completion.

Example logical behavior:

```text
main:
  create mutex/condition/shared state
  fork worker

worker:
  acquire mutex
  set shared state = 73
  signal condition
  release mutex

main:
  wait in predicate loop
  observe 73
  print THREAD-WITNESS-OK
```

Use actual Chez primitives and correct lock/condition semantics.

Do not busy-wait.

Do not use arbitrary sleeps as the correctness mechanism.

### Acceptance

A target-compatible native control prints:

```text
THREAD-WITNESS-OK
```

and exits cleanly.

If this cannot be achieved, do not proceed to Emscripten.

---

## 12. Work package D — Emscripten `tpb32l` without Jolt

Configure the exact pinned Chez revision for its threaded portable-bytecode Emscripten target.

The expected configuration family is approximately:

```sh
./configure \
  --emscripten \
  --threads \
  --pbarch \
  ...
```

Do not copy this literally until the pinned configure implementation confirms the exact combination and selected machine type.

Build with the thread witness as the application boot where appropriate.

Record the final compiler/linker commands sufficiently to demonstrate that pthread support actually reached both compilation and link steps.

### Node first

Run the resulting module under the Node version pinned by the Nix shell.

Required observations:

```text
Chez runtime started
target machine type identified as tpb32l
thread witness completed
THREAD-WITNESS-OK
exit status 0
```

Capture stderr independently from stdout where practical.

### Do not add Jolt yet

If Chez threading itself fails, Jolt cannot clarify the failure.

Reduce at this boundary.

---

## 13. Work package E — determine pthread pool requirements

Browser pthread creation differs materially from native pthread creation.

Do not immediately hide this by selecting a large worker pool.

Start with the most upstream-default threaded build.

If the browser or Node diagnostics show that synchronous thread creation or immediate waiting cannot progress because a worker has not started, test a **named variant** with a pre-created pool.

Use deterministic pool sizes.

Recommended investigation sequence:

```text
variant A: upstream/default pool behavior
variant B: fixed pool = 1
variant C: fixed pool = 2
variant D: fixed pool = 4, only if justified
```

Do not use `navigator.hardwareConcurrency` as the first reproducible witness because it makes the worker count host-dependent.

The experiment is not trying to minimize the pool size exhaustively. It is trying to establish whether a reasonable fixed pool permits the pinned runtime to initialize.

For every variant record:

* compile/link flags;
* worker count;
* startup behavior;
* worker errors;
* completion token;
* whether the main browser thread blocked;
* whether the runtime yielded to the event loop.

### Important failure mode

If Jolt or Chez performs a condition wait or join on the browser main thread before the required worker can begin, record that explicitly.

Do not respond by introducing `PROXY_TO_PTHREAD` inside EXP-014.

That result should motivate a separate experiment.

---

## 14. Work package F — genuine threaded Jolt boot under Node

Once T2 passes, rebuild the exact Jolt application payload for `tpb32l`.

Prefer reusing the same pure application fixture and canonical expected output from EXP-008 so that changing the Chez thread capability is the meaningful independent variable.

The desired comparison is:

```text
same Jolt revision
same source fixture
same expected canonical value

pb:
  FAIL before app witness at make-mutex

tpb32l:
  reaches app witness
```

Do not simplify the Jolt runtime by shadowing thread primitives.

Do not comment out worker initialization.

Do not replace mutexes with no-ops.

Do not use the threadless design.

### Cross-compilation

Use the generated target cross-compilation machinery from Work Package B.

Record:

```text
flat.ss source hash
target machine type
cross-compilation patch/xpatch hash
compiled FASL hash
boot composition
boot hash
```

The exact cross-compilation commands must be derived from the pinned Chez instructions and existing EXP-004/EXP-008 scripts.

### Node acceptance

The Jolt payload must:

* initialize;
* execute the canonical pure Jolt fixture;
* print a Jolt-specific startup token;
* print the expected canonical result;
* print a completion token;
* avoid uncaught Scheme/Jolt errors;
* avoid pthread startup errors.

Success here establishes that Chez `tpb32l` solves the EXP-008 startup blocker under Node.

It does not yet establish browser viability.

---

## 15. Work package G — browser threaded Chez control

Before testing Jolt in Chromium, serve the reduced threaded Chez witness.

The HTTP server must be loopback-only and emit at least:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Reuse the repository's existing serving infrastructure where possible.

The browser page must record:

```js
crossOriginIsolated
typeof SharedArrayBuffer
runtime readiness
thread witness completion
```

Browser automation must capture:

* page errors;
* console errors;
* worker errors visible through the harness;
* failed HTTP requests;
* response headers;
* readiness state;
* full-page screenshot.

This is not a visual-content experiment, so screenshot inspection only needs to establish that the intended diagnostic page loaded and displayed the expected status. No Raylib/canvas claim is made.

### Acceptance

The page reaches a stable:

```text
THREAD-WITNESS-OK
```

state with:

```text
crossOriginIsolated === true
SharedArrayBuffer available
```

and no relevant runtime/worker failure.

---

## 16. Work package H — genuine Jolt browser witness

Use the same Jolt application boot proven under Node.

Do not rebuild a different simplified browser-specific Jolt fixture unless a reduced browser failure requires it.

Publish stable state into the DOM.

Suggested diagnostic state machine:

```text
booting
chez-ready
jolt-entered
fixture-running
fixture-complete
failed
```

On failure, expose:

```text
stage
error class/category
message
```

without masking the original stderr/console output.

A successful page should expose something conceptually like:

```text
runtime=tpb32l
threads=enabled
crossOriginIsolated=true
jolt=ready
fixture=<canonical expected value>
status=complete
```

### Browser acceptance

Browser automation must prove:

1. the HTTP response is cross-origin isolated;
2. required Wasm/JS/data resources load;
3. pthread workers start;
4. Jolt reaches its application fixture;
5. canonical browser output equals the native/Node expected output;
6. no uncaught exception or Wasm trap occurs;
7. no relevant worker failure occurs;
8. page reaches stable completion.

This is T5 and the primary experiment success.

---

## 17. Work package I — Petite variant

Only begin after the full threaded T5 build passes.

Create a new named build variant that changes only what is necessary to use:

```text
--empetite
```

Preserve:

* exact Chez revision;
* exact Jolt revision;
* same `tpb32l` machine type;
* same pthread configuration;
* same worker-pool configuration;
* same Jolt application boot;
* same browser harness;
* same fixture;
* same expected output.

The key comparison must therefore be:

```text
full tpb32l Chez + Jolt app boot
vs
Petite tpb32l Chez + same Jolt app boot
```

Do not combine the Petite switch with unrelated optimization flags.

### Questions to answer

Determine experimentally:

1. Does the resulting Emscripten payload omit `scheme.boot` as expected?
2. Does Petite initialize the same Jolt runtime application boot?
3. Does Jolt startup require anything that was present only in full `scheme.boot`?
4. Does the canonical application fixture still pass?
5. Does browser pthread behavior remain unchanged?
6. What are the observed output artifact sizes?

### Petite acceptance

The exact same Jolt browser fixture reaches stable completion under the Petite build.

Record:

```text
scheme.js bytes
scheme.wasm bytes
scheme.data bytes
```

for both full and Petite variants.

Do not interpret those numbers as compressed download size.

Do not claim browser live eval.

If Petite runs the precompiled application but lacks facilities required for later live development, record that as an architectural profile distinction:

```text
release/minimal runtime candidate:
  Petite

development/runtime-compilation candidate:
  full Chez, subject to later proof
```

Do not investigate the development profile further in EXP-014.

---

## 18. Failure classification

Use the existing repository categories.

### `ENVIRONMENT`

Examples:

* missing required host compiler despite correct Nix shell;
* incompatible sandbox restriction;
* browser unavailable;
* accidental mutable external SDK dependency.

### `CHEZ_EMSCRIPTEN`

Examples:

* `tpb32l` target boots cannot be generated;
* Emscripten Chez cannot configure against valid generated boots;
* threaded Chez kernel fails before Jolt involvement;
* target machine construction is internally inconsistent.

### `EMSCRIPTEN_LINK`

Examples:

* correct Chez threaded objects are produced but pthread-linked Wasm cannot link;
* missing Emscripten symbols;
* mismatched compile/link pthread mode.

### `BROWSER_SECURITY`

Examples:

* `SharedArrayBuffer` unavailable because isolation is not established;
* required COOP/COEP state absent;
* worker loading rejected by browser policy.

### `JOLT_CHEZ_HOST`

Examples:

* Jolt emitted source cannot be compiled for `tpb32l`;
* machine-type assumptions in Jolt break on `tpb32l`;
* Jolt boot construction fails independently of Emscripten.

### `JOLT_THREAD_CAPABILITY`

Examples:

* threaded Chez works, but Jolt depends on thread behavior not provided correctly by the target;
* thread-parameter inheritance differs in a way that breaks Jolt semantics;
* Jolt initializes but its required concurrency primitives behave incompatibly.

### `UNKNOWN`

Use only until a reduced witness assigns the failure to a more specific boundary.

A browser-main-thread scheduling deadlock should be reduced before categorization. Do not automatically label every pthread failure `JOLT_THREAD_CAPABILITY`.

---

## 19. Browser-main-thread stop condition

A particularly valuable result would be:

```text
Node threaded Jolt: PASS
Chromium threaded Chez: PASS
Chromium threaded Jolt: FAIL because Jolt blocks browser main thread
```

If this is observed, EXP-014 is complete.

Do not add:

```text
-sPROXY_TO_PTHREAD
OffscreenCanvas
Raylib proxying
canvas transfer
```

inside this experiment.

Record the exact wait/join/condition site if it can be reduced.

Propose a separate follow-up experiment such as:

```text
EXP-015-jolt-proxy-to-pthread
```

whose purpose is specifically to test whether Jolt can own a pthread while the browser main thread remains available for host scheduling.

That experiment would need to reconsider eventual Raylib/canvas ownership separately.

---

## 20. Patch discipline

Start with **zero upstream patches**.

A patch is permitted only after:

1. the stock pinned revision fails;
2. a reduced witness identifies the exact upstream layer;
3. the original failure log is retained;
4. the smallest patch is proposed;
5. the patch does not merely bypass a semantic requirement.

Any patch must live under:

```text
experiments/EXP-014-jolt-tpb32l-emscripten/patches/
```

and document:

```text
upstream project
exact base revision
problem
no-patch reproduction
patch intent
changed files
why project-local configuration is insufficient
validation
upstream suitability
```

Do not patch Jolt merely to make it "less threaded".

That would be a different research path.

---

## 21. Required artifacts

Generated artifacts remain ignored unless repository policy explicitly says otherwise.

Retain under `artifacts/logs/EXP-014/` at minimum:

```text
environment.log
pb-control.log

bootquick-tpb32l.log
bootquick-files.txt
bootquick-hashes.txt

native-thread-witness.log
emscripten-thread-build.log
node-thread-witness.log

jolt-tpb32l-compile.log
jolt-tpb32l-boot.log
jolt-node.log

browser-server.log
browser-response-headers.txt
browser-console.json
browser-page-errors.json
browser-request-failures.json
browser-worker-diagnostics.json
browser-status.json

jolt-browser-full.json
jolt-browser-petite.json

artifact-sizes-full.txt
artifact-sizes-petite.txt
artifact-hashes-full.txt
artifact-hashes-petite.txt
```

Use actual filenames produced by the project harness; the above names define the information required, not mandatory spelling.

The experiment README must point to and interpret the important artifacts.

---

## 22. `commands.sh` requirements

`commands.sh` must:

```sh
#!/usr/bin/env bash
set -euo pipefail
```

It must run from repository root or detect and normalize its working directory.

Do not hide status through pipelines.

Where output is piped to `tee`, preserve the producing command's exit status.

Prefer explicit staged commands over one opaque mega-build.

Useful high-level modes are acceptable, for example:

```text
commands.sh control
commands.sh bootquick
commands.sh native-thread
commands.sh em-thread-node
commands.sh jolt-node
commands.sh em-thread-browser
commands.sh jolt-browser
commands.sh petite-browser
commands.sh all
```

Do not add modes that merely duplicate reusable project scripts.

Every mode should print:

```text
experiment id
stage
source revisions
target machine type
variant
output/log path
PASS/FAIL token
```

---

## 23. Reproducibility requirements

The experiment must work from the pinned Nix shell.

Do not depend on:

* globally activated `emsdk`;
* user's shell aliases;
* mutable Chez installation;
* host browser profiles;
* machine-local absolute source paths;
* unrecorded boot files from a sibling checkout;
* previously generated Wasm caches for correctness.

Generated target boots may be cached for speed, but `commands.sh` must be able to regenerate them from the pinned source.

Record whether an Emscripten cache was warm or cold only if it affects investigation; cache performance is not an acceptance criterion.

---

## 24. Beads decomposition

Beads remains the live task tracker.

Do not duplicate task completion state into this plan.

Create a small dependency graph approximately corresponding to:

```text
A. reproduce EXP-008 control
        ↓
B. generate pinned tpb32l boots
        ↓
C. prove native tpb32l thread witness
        ↓
D. prove Emscripten tpb32l under Node
        ↓
E. mint genuine Jolt tpb32l boot
        ↓
F. prove Jolt tpb32l under Node
        ↓
G. prove threaded Chez under Chromium
        ↓
H. prove Jolt under Chromium
        ↓
I. prove Petite variant
        ↓
J. update evidence documentation
```

If an unexpected blocker requires source investigation or an upstream patch, create a separate bead and wire it into this graph instead of expanding the claimed task silently.

Difficulty assignments should reflect uncertainty rather than volume.

Likely:

```text
boot generation/cross-target investigation: hard
Jolt tpb32l boot integration: hard
Emscripten pthread/browser diagnosis: hard
browser harness adaptation: medium
Petite comparison: medium
artifact/report updates: easy
```

---

## 25. Commit discipline

Follow repository `AGENTS.md`.

Make small commits after validated boundaries.

A suitable sequence if everything succeeds would be approximately:

```text
exp014: add threaded tpb32l experiment scaffold

exp014: generate and validate tpb32l Chez target

exp014: prove threaded Chez under Emscripten Node

exp014: run genuine Jolt boot on threaded Node Wasm

exp014: prove threaded Chez browser runtime

exp014: prove Jolt browser runtime

exp014: add Petite threaded runtime variant

docs: record EXP-014 evidence and implications
```

Do not manufacture this sequence if implementation naturally produces different atomic boundaries.

Never commit generated caches or large Wasm build outputs merely to prove they existed.

---

## 26. Documentation updates after evidence

Do not update conclusions before the relevant gate passes.

### If T0–T2 only pass

Update the EXP-014 README.

Root `REPORT.md` may note that threaded Emscripten Chez itself is viable, but Jolt remains blocked.

### If T3 passes

Record that the previous `make-mutex` blocker is solved under threaded Node Wasm.

Do not claim Jolt/browser.

### If T5 passes

Update:

```text
REPORT.md
docs/ARCHITECTURE.md
docs/DEVELOPMENT.md
docs/GOTCHAS.md
```

only where the new observation changes demonstrated architecture.

The report should state clearly:

```text
Jolt threadless adapter is no longer a prerequisite for the demonstrated
browser configuration.

The demonstrated configuration instead depends on Emscripten pthreads,
cross-origin isolation, and a generated tpb32l Chez target.
```

Do not erase the `pb` failure.

Both observations remain true:

```text
pb browser Jolt:
  blocked by missing thread capability

tpb32l browser Jolt:
  <observed result>
```

### If T6 passes

Record Petite as a demonstrated deployment/runtime variant.

Do not claim it supports runtime compilation or live redefinition.

---

## 27. Success implications for the main project

A T5 or T6 success changes the next research path substantially.

The immediate next experiment should no longer be a Jolt threadless adapter.

Instead resume the original proof ladder at the Jolt → static facade boundary:

```text
threaded Jolt browser runtime
        ↓
verified signed-scalar Jolt FFI declaration
        ↓
project-owned C facade
        ↓
Raylib
        ↓
first Jolt-driven frame
```

The existing EXP-006/EXP-007 findings remain valid:

* static symbol registration is viable;
* signed `integer-32` is the measured safe starting ABI;
* C/browser ownership of Raylib has already been demonstrated with Scheme.

Do not combine that work into EXP-014.

---

## 28. Failure implications

A well-reduced failure is a successful research outcome.

### Case A — cannot generate `tpb32l` boots

Conclusion:

```text
pinned Chez threaded Emscripten route blocked before Jolt
```

Next work should investigate Chez target generation/upstream support.

### Case B — native `tpb32l` works but Emscripten threaded Chez fails

Conclusion:

```text
Chez tpb32l target exists, but its Emscripten realization is blocked
```

Reduce against Chez/Emscripten before touching Jolt.

### Case C — threaded Chez Wasm works but Jolt Node fails

Conclusion:

```text
Jolt has a tpb32l/threaded portable-bytecode compatibility blocker
```

Reduce Jolt's host assumptions.

### Case D — Jolt Node works but browser Chez thread witness fails

Conclusion:

```text
browser pthread/runtime environment blocks the target independent of Jolt
```

Investigate Emscripten/browser thread constraints.

### Case E — threaded Chez browser works but Jolt browser fails

Conclusion:

```text
Jolt uses thread/blocking behavior incompatible with browser-main-thread execution
```

This strongly motivates a separate `PROXY_TO_PTHREAD` experiment.

### Case F — full threaded Jolt browser works but Petite fails

Conclusion:

```text
threaded Jolt browser execution is feasible;
Petite packaging is separately incompatible with current Jolt boot/runtime requirements
```

Continue with the full Chez profile. Do not turn a Petite failure into a Jolt/Wasm failure.

---

## 29. Final acceptance criteria

EXP-014 may be marked **PASS** only if at least T5 is observed:

> A genuine exact-revision Jolt payload executes under pinned threaded Chez `tpb32l` compiled with Emscripten pthreads in Chromium, under explicit cross-origin isolation, reaches the canonical application witness, and produces no relevant uncaught runtime or worker failure.

T6 is an additional success:

> The same fixture executes with `--empetite` using the same threaded target and browser configuration.

A lower level must be marked **PARTIAL** with the exact achieved boundary.

A reduced hard blocker must be marked **FAIL / REDUCED BLOCKER**, not as incomplete implementation.

---

## 30. Required final README summary

At handoff, `experiments/EXP-014-jolt-tpb32l-emscripten/README.md` should be able to answer, in its first screen:

```text
Did pinned Chez generate tpb32l boots?
Did threaded Chez run under Node?
Did genuine Jolt run under threaded Node Wasm?
Did threaded Chez run under Chromium?
Did genuine Jolt run under Chromium?
Was crossOriginIsolated true?
Was a pthread pool required?
Did --empetite work?
What is the first remaining blocker?
What exact command reproduces the highest demonstrated level?
```

Include one concise result table:

| Gate                        | Result | Evidence       |
| --------------------------- | ------ | -------------- |
| T0 generated `tpb32l` boots | TBD    | log/hash       |
| T1 native thread witness    | TBD    | log            |
| T2 Emscripten Chez / Node   | TBD    | log            |
| T3 Jolt / Node              | TBD    | log            |
| T4 Chez / Chromium          | TBD    | browser report |
| T5 Jolt / Chromium          | TBD    | browser report |
| T6 Petite Jolt / Chromium   | TBD    | browser report |

Replace `TBD` only with observed results.

---

## 31. Decision rule

The experiment exists to make one architectural decision.

After completion:

```text
if T5 passes:
    continue Jolt + Raylib work on threaded tpb32l
    keep threadless adapter as optional future portability work

elif Jolt works under Node and browser-main-thread semantics are the blocker:
    create isolated PROXY_TO_PTHREAD experiment

elif threaded Chez works but Jolt is incompatibly threaded:
    reduce Jolt target/thread semantics before deciding between
    threadless adapter and other threading topology

elif threaded Chez itself cannot be made viable:
    return to the documented Jolt threadless browser adapter path
```

Do not choose the threadless implementation merely because EXP-008 failed on `pb`.

Do not choose the threaded implementation merely because `tpb32l` builds.

The decision must be based on the highest runtime evidence obtained by this experiment.
