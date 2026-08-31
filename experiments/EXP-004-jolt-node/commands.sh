#!/usr/bin/env bash
# Record the exact-host boundary for EXP-004. Run from repository root via Nix.
set -euo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
chez_source="$root/build/EXP-003-jolt-tpb32l/source"
pack="$root/build/EXP-003-jolt-tpb32l/pack"
chez="$chez_source/tpb64l/bin/tpb64l/scheme"
log_dir="$root/artifacts/logs/EXP-004"
mkdir -p "$log_dir"

[[ -x "$chez" ]] || {
  printf 'build EXP-003 first: %s\n' "$chez" >&2
  exit 1
}
CHEZ_SRC="$chez_source" "$root/../jolt/tools/cross-compile/make-pack.sh" tpb64l "$pack"
{
  printf 'jolt_revision='
  git -C "$root/../jolt" rev-parse HEAD
  printf 'chez_executable=%s\n' "$chez"
  "$chez" --version
  printf '(display (machine-type)) (newline) (display (threaded?)) (newline) (exit)\n' | "$chez" -q
  printf 'JOLT_CHEZ=%s\nJOLT_CHEZ_CSV=%s\n' "$chez" "$pack"
} >"$log_dir/exact-host-metadata.log"

# The expected result is either a target payload or the first post-host failure.
# Do not replace this exact host with /usr/bin/scheme.
set +e
JOLT_CHEZ="$chez" JOLT_CHEZ_CSV="$pack" "$root/../jolt/bin/jolt" build \
  -m app.witness -o "$root/build/EXP-004-jolt-node/app" \
  --target tpb64l --target-pack "$pack" \
  >"$log_dir/exact-host-cross-build.log" 2>&1
status=$?
set -e
printf 'exit_status=%s\n' "$status" >>"$log_dir/exact-host-cross-build.log"
exit "$status"
