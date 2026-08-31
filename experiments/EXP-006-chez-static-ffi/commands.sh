#!/usr/bin/env bash
# Build the patched no-argument control in the pinned Nix environment.
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
export CHEZ_EXPERIMENT=EXP-006-chez-static-ffi
export CHEZ_WITNESS="$root/experiments/EXP-006-chez-static-ffi/witness-noarg.ss"
export CHEZ_PATCH="$root/experiments/EXP-006-chez-static-ffi/project-custom-init.patch"
"$root/scripts/chez-wasm-build"
(
  cd "$root/build/$CHEZ_EXPERIMENT/source/em-pb/bin/pb"
  node scheme.js
)
