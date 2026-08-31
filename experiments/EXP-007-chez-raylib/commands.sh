#!/usr/bin/env bash
# Build one EXP-007 scene. SCENE must be green or red.
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
scene=${SCENE:-green}
[[ "$scene" == green || "$scene" == red ]] || { echo 'SCENE must be green or red' >&2; exit 2; }
export CHEZ_EXPERIMENT="EXP-007-chez-raylib-$scene"
export CHEZ_WITNESS="$root/experiments/EXP-007-chez-raylib/witness-$scene.ss"
export CHEZ_PATCH="$root/experiments/EXP-007-chez-raylib/project-raylib-init.patch"
export CHEZ_EM_CPPFLAGS="-I$RAYLIB_SOURCE/src -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2"
export CHEZ_EM_LDFLAGS="-L$root/build/EXP-005-raylib-web -lraylib -sUSE_GLFW=3 -sASSERTIONS=1 -sWASM=1"
"$root/scripts/raylib-web-build" >/dev/null
"$root/scripts/chez-wasm-build"
bin="$root/build/$CHEZ_EXPERIMENT/source/em-pb/bin/pb"
cp "$root/experiments/EXP-007-chez-raylib/web/index.html" "$bin/index.html"
