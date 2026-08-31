# EXP-014 patch discipline

No patch is expected or present at experiment creation.

A project-local patch may be added here only after the exact pinned upstream
revision fails under a retained no-patch reproduction and a reduced witness
locates the responsible layer. Its accompanying documentation must identify:

- upstream project and exact base revision;
- problem and no-patch command/log;
- smallest intended change and changed files;
- why project configuration cannot solve it;
- validation and upstream suitability.

A patch must not make Jolt less threaded, shadow mutex/condition primitives, or
otherwise bypass the semantic target of this experiment. Generated target boots
and Emscripten outputs are evidence artifacts, not patches.
