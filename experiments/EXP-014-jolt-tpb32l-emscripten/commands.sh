#!/usr/bin/env bash
# Stage-oriented reproduction for EXP-014. Run through the pinned Nix shell.
set -euo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
experiment=EXP-014-jolt-tpb32l-emscripten
log_dir="$root/artifacts/logs/EXP-014"
stage=${1:-}

usage() {
  cat >&2 <<'USAGE'
usage: commands.sh control|bootquick

control    Record the pinned environment and rerun the genuine non-threaded
           EXP-008 Jolt pb control. It is expected to abort at make-mutex.
bootquick  Copy the pinned Chez source, build its portable pb host, and run the
           documented `make bootquick XM=tpb32l` target generator.

Later stages are intentionally unavailable until their owning Beads work package
has established the preceding gate. Do not infer an Emscripten runtime from
boot generation.
USAGE
  exit 64
}

log_run() {
  local log=$1
  shift
  set +e
  "$@" 2>&1 | tee "$log"
  local status=${PIPESTATUS[0]}
  set -e
  printf 'exit_status=%s\n' "$status" >>"$log"
  return "$status"
}

metadata() {
  printf 'experiment=%s\nstage=%s\n' "$experiment" "$stage"
  printf 'repository_revision='; git -C "$root" rev-parse HEAD
  printf 'jolt_revision='; git -C "$root/../jolt" rev-parse HEAD
  printf 'chez_pin=7fadeee45fcc0135b17f5c1a926157004f898339\n'
  printf 'target_machine=pb (non-threaded control only)\n'
  printf 'variant=stock-pb-jolt-control\n'
}

[[ $# -eq 1 ]] || usage
mkdir -p "$log_dir"
case "$stage" in
  control)
    metadata | tee "$log_dir/control-metadata.log"
    log_run "$log_dir/bootstrap.log" nix develop -c "$root/scripts/bootstrap"
    if log_run "$log_dir/pb-control.log" nix develop -c "$root/experiments/EXP-008-jolt-browser/commands.sh"; then
      printf '%s CONTROL-UNEXPECTED-PASS\n' "$experiment" >&2
      exit 1
    else
      status=$?
      if grep -Fq 'Call error: (1 0 #{make-mutex *top*:make-mutex} ())' "$log_dir/pb-control.log" \
        && grep -Fq 'exit_status=134' "$log_dir/pb-control.log"; then
        printf '%s CONTROL-EXPECTED-FAIL status=%s log=%s\n' \
          "$experiment" "$status" "$log_dir/pb-control.log"
        exit 0
      fi
      printf '%s CONTROL-WRONG-FAILURE status=%s log=%s\n' \
        "$experiment" "$status" "$log_dir/pb-control.log" >&2
      exit "$status"
    fi
    ;;
  bootquick)
    work="$root/build/$experiment/source"
    rm -rf "$work"
    nix develop -c bash -c 'cp -RL "$CHEZ_SOURCE"/. "$1"; chmod -R u+w "$1"' _ "$work"
    metadata | sed 's/target_machine=.*/target_machine=tpb32l/' | tee "$log_dir/bootquick-metadata.log"
    log_run "$log_dir/bootquick-tpb32l.log" bash -c "cd '$work' && ./configure --pb --disable-x11 --disable-curses && make -j\"\${JOBS:-2}\" && make bootquick XM=tpb32l"
    find "$work/boot/tpb32l" "$work/xc-tpb32l" -type f -print | sort >"$log_dir/bootquick-files.txt"
    sha256sum "$work/boot/tpb32l/petite.boot" "$work/boot/tpb32l/scheme.boot" "$work/xc-tpb32l/s/xpatch" >"$log_dir/bootquick-hashes.txt"
    printf '%s BOOTQUICK-PASS target=tpb32l log=%s\n' "$experiment" "$log_dir/bootquick-tpb32l.log"
    ;;
  *) usage ;;
esac
