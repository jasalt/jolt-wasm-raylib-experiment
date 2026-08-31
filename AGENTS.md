# Agent instructions — Jolt Chez-Wasm Raylib experiment

This repository is an evidence-driven experiment for running Jolt through Chez
Scheme's Emscripten portable-bytecode target and rendering with Raylib in a web
browser.

Read [README.md](README.md) for the human-facing overview and then read
[PLAN.md](PLAN.md) completely before planning or implementing work. `PLAN.md` is
the governing research specification; Beads is the live task system.

## Required upstream reading

Before changing the project:

1. read this file, `README.md`, and `PLAN.md`;
2. read the workspace guidance in `../AGENTS.md`;
3. read Jolt repository guidance in `../jolt/llms.txt`;
4. read `../jolt-lang.github.io/docs/llms.txt` or
   <https://jolt-lang.net/llms.txt>;
5. follow the specific Jolt documentation, specifications, RFCs, and source
   implicated by the task; and
6. inspect the pinned Chez, Raylib, and `../raylib-jlt` source rather than
   relying on general platform assumptions.

Useful starting points:

- <https://jolt-lang.net/docs/scheme-backends.html>
- <https://jolt-lang.net/docs/repl-driven-development.html>
- <https://jolt-lang.net/docs/native-interop.html>
- `../jolt/host/scheme-adapter/TARGET-CONTRACT.md`
- `../jolt/host/scheme-adapter/THREADS.md`
- <https://github.com/cisco/ChezScheme/blob/main/BUILDING>
- <https://github.com/cisco/ChezScheme/issues/876>
- `../raylib-jlt/README.md`
- <https://github.com/raysan5/raylib/wiki/Working-for-Web-(HTML5)>

When documentation and implementation disagree, prefer pinned current source,
tests, and reduced observations. There is no JVM under Jolt. Do not infer JVM
interop, strings, threads, GC, process lifetime, or FFI behavior.

## Environment

The workspace may be a restricted Jai jail, an x86_64 Fedora Lima VM, or another
host. Inspect it instead of assuming root, graphics, browser, network, or
hardware acceleration:

```sh
env | grep -E '^(HOSTNAME|JAI_|DISPLAY|WAYLAND_DISPLAY)='
uname -a
```

Use the pinned Nix shell once it exists. Do not add machine-local SDK paths,
globally activated Emscripten state, mutable browser profiles, or host package
assumptions to project configuration.

## Evidence rules

- Distinguish **proposed**, **observed**, **inferred**, and **blocked** behavior.
- Start every uncertainty with the smallest isolated experiment in
  `experiments/EXP-NNN-*/`.
- Preserve exact source revisions, commands, environment, exit status, logs,
  screenshots, and hashes.
- A workaround does not erase the original failure or change its category.
- Do not patch Jolt, Chez, Raylib, or Raylib-Jolt before a reduced no-patch
  witness identifies the failing layer.
- Never report a test as passing when a pipeline masked its exit status.
- Do not claim a browser render from build success, process survival, console
  text, or an image written only inside Emscripten's virtual filesystem.

Web rendering validation must use browser automation against an HTTP server.
Capture page errors, console errors, request failures, readiness state, and
full-page plus canvas screenshots. A coding agent with vision capability must
inspect semantic screenshot content and record the observation. Pixel checks
support but do not replace visual inspection.

Keep generated Wasm/JS/data, boot files, browser profiles, and caches ignored
unless a specific experiment justifies committing a small hashed artifact.

## REPL-driven workflow

Use normal loopback Jolt nREPL first for portable model, update, layout, and
command-generation code. Evaluate small forms, observe them, and turn successful
observations into tests before rebuilding Wasm.

A native nREPL worker does not own Raylib. Never invoke Raylib drawing, input,
resource, lifecycle, or shutdown FFI from an evaluator worker. Browser live eval,
when implemented, must be debug-only and queued for bounded execution by the
proven frame owner between frames. Release output must not expose arbitrary eval.

Long-running code intended for redefinition must call Vars dynamically; do not
capture a startup function value and then claim redefinition works.

## Source and documentation conventions

Before adding source, create `src/README.md` describing the overall source
architecture. Every source subdirectory gets its own narrower README with or
before its first source file. Use Markdown fenced `d2` diagrams where ownership,
data flow, or dependencies benefit from a visual explanation.

Documentation roles:

- `README.md` — concise human overview and entry links;
- `AGENTS.md` — agent process and safety rules;
- `PLAN.md` — proof order and acceptance criteria, not task status;
- `docs/ARCHITECTURE.md` — demonstrated architecture only;
- `docs/DEVELOPMENT.md` — commands proven to work;
- `docs/GOTCHAS.md` — evidence-backed traps;
- `experiments/` — reduced reproductions and artifacts;
- `REPORT.md` — final graded conclusion;
- Beads — all changing tasks and durable discoveries.

Avoid duplicating long content between these files.

## Beads is the only task system

Run at session start:

```sh
bd dolt pull
bd prime
bd ready
```

Claim exactly one ready bead with `bd update <id> --claim`. If unexpected work
appears, create a bead and wire dependencies rather than silently broadening the
current task. Use `bd remember` for durable discoveries. Add exact validation
evidence to the bead and do not close it on inference.

Use Beads commands, never direct database or JSONL edits. Beads uses the same
Git repository's remote through `refs/dolt/data`; source Git commits and
Beads/Dolt commits are separate and both must be synchronized.

## Commit and push workflow

The project requires small atomic commits during progress and pushes after
validated increments. Before committing:

1. inspect Git and Beads status;
2. run the focused gates for the claimed bead;
3. inspect screenshots with vision when the bead makes a visual claim;
4. update or close the bead with exact evidence;
5. review the source diff and generated artifacts; and
6. ensure unrelated user changes are not included.

Then make one focused source commit, commit matching Beads/Dolt state, rebase
safely against the remote, push both stores, and verify synchronized clean
status. Never claim a commit or push happened unless the command succeeded.
A later explicit user instruction not to commit or push overrides this standing
project rule.

## Working conventions

- Inspect existing files and status before editing.
- Prefer project scripts over undocumented shell history.
- Make scripts fail fast and produce actionable diagnostics.
- Use `.cljc` for genuinely portable code and `.jolt` for Jolt/host-specific
  interop where that distinction helps readers.
- Keep browser servers loopback-only and emit required COOP/COEP headers for
  pthread builds.
- Treat frame ownership, Scheme object roots held by C, foreign memory, strings,
  and callback lifetime as unproven until focused tests pass.
- Do not expose debug eval in release output.
- Report commands, evidence, commit hashes, pushed remotes, and remaining
  uncertainty concisely at handoff.
