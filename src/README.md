# Source architecture

This directory will hold only project-owned code. Portable Jolt model code is
kept separate from the narrow Raylib facade and C/browser ownership layers.
No source exists yet beyond the Phase 0 native witness.

```d2
app: "portable Jolt app" -> raylib: "Jolt facade"
raylib -> native: "C ABI facade"
native -> web: "browser shell / frame owner"
```
