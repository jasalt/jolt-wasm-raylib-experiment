#!/usr/bin/env bash
# Reproduce the first genuine Jolt boot boundary on pinned native pb.
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
src="$root/build/EXP-006-chez-static-ffi/source"
flat="$root/build/EXP-004-jolt-node/app.build/flat.ss"
out="$root/build/EXP-008-jolt-browser"
[[ -x "$src/pb/bin/pb/scheme" && -f "$flat" ]] || {
  echo 'run EXP-004 and EXP-006 first' >&2
  exit 2
}
rm -rf "$out"
mkdir -p "$out"
cp "$flat" "$out/flat.ss"
(
  cd "$src"
  pb/bin/pb/scheme --script /dev/stdin <<SCHEME
(import (chezscheme))
(optimize-level 2)
(generate-inspector-information #t)
(generate-procedure-source-information #t)
(fasl-compressed #t)
(compile-file "$out/flat.ss" "$out/flat.so")
(make-boot-file "$out/jolt.boot" '()
  "pb/boot/pb/petite.boot" "pb/boot/pb/scheme.boot" "$out/flat.so")
SCHEME
  pb/bin/pb/scheme -b "$out/jolt.boot"
)
