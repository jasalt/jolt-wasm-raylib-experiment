#!/usr/bin/env bash
set -euo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
base="$root/build/EXP-014-jolt-tpb32l-emscripten"
work="$root/build/EXP-016-jolt-scene"
pack="$base/pack-libffi-raylib-input"
out="$root/build/EXP-016-app"

[[ -x "$work/tpb64l/bin/tpb64l/scheme" ]] || {
  echo 'EXP-016 reuses the exact EXP-014 patched source/host tree; build it first.' >&2
  exit 1
}

rm -rf "$out" "$out.build"
nix shell "$root#i686-cc" -c bash -c '
  export JOLT_CHEZ="$1/tpb64l/bin/tpb64l/scheme"
  export JOLT_CHEZ_CSV="$1/tpb64l/boot/tpb64l"
  export JOLT_TARGET_CC=gcc
  "$2/bin/jolt" build -m app.exp016 -o "$3" \
    --target tpb32l --target-pack "$4"
' _ "$work" "$base/jolt-libffi" "$out" "$pack"

nix develop "$root" -c bash -c '
  cd "$1"
  CFLAGS="-DDISABLE_CURSES" \
  CPPFLAGS="-I$RAYLIB_SOURCE/src -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2 -I$2/install/include" \
  LDFLAGS="-L$3 -lraylib -sUSE_GLFW=3 -sASSERTIONS=1 -sWASM=1 -L$2/install/lib -s PTHREAD_POOL_SIZE=1" \
  ./configure --emscripten --threads --pbarch --enable-libffi \
    --emboot="$4" --disable-x11 --disable-curses
  make -j2
' _ "$work" "$base/libffi-em" "$root/build/EXP-005-raylib-web" \
  "$out.build/jolt.boot"

"$root/experiments/EXP-016-jolt-scene/browser-smoke"
