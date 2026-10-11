#!/usr/bin/env bash
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
base="$root/build/EXP-014-jolt-tpb32l-emscripten"
work="$root/build/EXP-017-flappy"
out="$root/build/EXP-017-app-upstream"
pack=${JOLT_TARGET_PACK:-"$root/build/EXP-018-pack"}
jolt=${JOLT_PROJECT_SOURCE:-"$root/build/EXP-017-jolt-upstream"}
jolt_revision=${JOLT_PROJECT_REVISION:-5b46858a171f30949f5b09eb484bc6c5ff93c6ea}
[[ "$(cat "$jolt/UPSTREAM_REVISION")" == "$jolt_revision" ]] || {
  echo "prepare an unmodified upstream Jolt archive at $jolt_revision in $jolt" >&2
  exit 1
}
host_scheme=${JOLT_BUILD_CHEZ:-"$root/build/EXP-018-chez-native/ta6le/bin/ta6le/scheme"}
host_csv=${JOLT_BUILD_CSV:-"$root/build/EXP-018-chez-native/ta6le/boot/ta6le"}
[[ -x "$host_scheme" && -f "$pack/xpatch" ]] || {
 echo 'run experiments/EXP-018-jolt-size/commands.sh prepare first' >&2
 exit 1
}
rm -rf "$out" "$out.build"
nix shell "$root#i686-cc" -c bash -c '
 export JOLT_NARROW_HASH=1
 export JOLT_CHEZ="$1" JOLT_CHEZ_CSV="$2" JOLT_TARGET_CC=gcc
 "$3/bin/jolt" build -m app.exp017 -o "$4" --target tpb32l --target-pack "$5"
' _ "$host_scheme" "$host_csv" "$jolt" "$out" "$pack"
cat >> "$out.build/flat.ss" <<'SCHEME'
;; Owner-thread callback resolves the live Jolt frame! Var on every frame.
(define (exp017-frame)
  (jolt-invoke0 (var-cell-deref (jolt-var "app.exp017" "frame!"))))
SCHEME
rm -f "$out.build/flat.so" "$out.build/jolt.boot"
JOLT_NARROW_HASH=1 nix shell "$root#i686-cc" -c \
  "$host_scheme" --script "$out.build/compile.ss"
nix develop "$root" -c bash -c '
 cd "$1"
 CFLAGS="-DDISABLE_CURSES" CPPFLAGS="-I$RAYLIB_SOURCE/src -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2 -I$2/install/include" LDFLAGS="-L$3 -lraylib -sUSE_GLFW=3 -sASSERTIONS=1 -sWASM=1 -L$2/install/lib -s PTHREAD_POOL_SIZE=1" ./configure --emscripten --threads --pbarch --enable-libffi --emboot="$4" --disable-x11 --disable-curses
 make -j2
' _ "$work" "$base/libffi-em" "$root/build/EXP-005-raylib-web" "$out.build/jolt.boot"
JOLT_PROJECT_REVISION="$jolt_revision" "$root/experiments/EXP-017-jolt-flappy/browser-smoke"
