#!/usr/bin/env bash
# Requires the existing EXP-014/017 prerequisite build tree. Run in nix develop.
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$root"
exp=EXP-018
mkdir -p "artifacts/logs/$exp" "artifacts/reports/$exp"
case ${1:-compare} in
prepare)
  [[ $(uname -m) == x86_64 ]] || { echo 'This native host witness is x86_64-only' >&2; exit 1; }
  : "${CHEZ_SOURCE:?run with nix develop -c}"
  : "${JOLT_SOURCE:?run with nix develop -c}"
  host="$root/build/EXP-018-chez-native"
  if [[ ! -x "$host/ta6le/bin/ta6le/scheme" ]]; then
    mkdir -p "$host"
    cp -RL "$CHEZ_SOURCE"/. "$host"/
    chmod -R u+w "$host"
    (cd "$host"; ./configure --threads --disable-x11 --disable-curses; make -j2)
  fi
  (cd "$host"; make bootquick XM=tpb32l)
  cp -a "$root/build/EXP-014-jolt-tpb32l-emscripten/pack-libffi-raylib-input" "$root/build/EXP-018-pack.tmp"
  cp "$host/xc-tpb32l/s/xpatch" "$root/build/EXP-018-pack.tmp/xpatch"
  rm -rf "$root/build/EXP-018-pack"
  mv "$root/build/EXP-018-pack.tmp" "$root/build/EXP-018-pack"
  # Nix input includes exact pinned submodules; a git archive alone does not.
  rm -rf "$root/build/EXP-017-jolt-upstream"
  mkdir -p "$root/build/EXP-017-jolt-upstream"
  cp -RL "$JOLT_SOURCE"/. "$root/build/EXP-017-jolt-upstream"/
  chmod -R u+w "$root/build/EXP-017-jolt-upstream"
  printf '%s\n' 5b46858a171f30949f5b09eb484bc6c5ff93c6ea > "$root/build/EXP-017-jolt-upstream/UPSTREAM_REVISION"
  ;;
snapshot-baseline|snapshot-updated)
  label=${1#snapshot-}
  dest="$root/build/EXP-018-$label"
  mkdir -p "$dest"
  cp build/EXP-017-flappy/em-tpb32l/bin/tpb32l/scheme.{wasm,data,js} "$dest"/
  cp build/EXP-017-app-upstream.build/jolt.boot "$dest"/
  cp artifacts/reports/EXP-017-browser.json "artifacts/reports/$exp/$label-browser.json"
  cp artifacts/screenshots/EXP-017/{page,canvas}.png "$dest"/
  ;;
compare)
  python3 experiments/EXP-018-jolt-size/measure.py build/EXP-018-baseline build/EXP-018-updated "artifacts/reports/$exp/sizes.json"
  ;;
*) echo "usage: $0 prepare|snapshot-baseline|snapshot-updated|compare" >&2; exit 2 ;;
esac
