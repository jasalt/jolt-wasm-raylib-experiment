#!/usr/bin/env bash
# Stage-oriented reproduction for EXP-014. Run through the pinned Nix shell.
set -euo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
experiment=EXP-014-jolt-tpb32l-emscripten
log_dir="$root/artifacts/logs/EXP-014"
stage=${1:-}

usage() {
  cat >&2 <<'USAGE'
usage: commands.sh control|bootquick|native-thread|em-thread-node|host64-pack|jolt-mint|jolt-node

control    Record the pinned environment and rerun the genuine non-threaded
           EXP-008 Jolt pb control. It is expected to abort at make-mutex.
bootquick      Copy the pinned Chez source, build its portable pb host, and run
               the documented `make bootquick XM=tpb32l` target generator.
native-thread   Build and run the actual 32-bit tpb32l witness with the flake's
                pinned i686 compiler (not host `-m32` multilib).
em-thread-node  Build the same witness in threaded Emscripten Chez and execute
                it with Node using named pre-created pthread pool size 1.
host64-pack     Build a pinned tpb64l cross host, generate its tpb32l xpatch,
                and build the target kernel in the same Chez tree.
jolt-mint       Apply the reviewed Jolt word-size patch to a copied pinned tree,
                run 64/32-bit hash gates, and mint the unchanged tpb32l app boot.
jolt-node       Cross-build pinned libffi, apply the reviewed Chez Emscripten
                FFI delta, mint the unchanged app, and prove T3 under Node.

`jolt-node` is the highest demonstrated command. It retains the exact patched
sources, compiler/link flags, native expected output, and Node output.
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
  printf 'repository_revision='
  git -C "$root" rev-parse HEAD
  printf 'jolt_revision='
  git -C "$root/../jolt" rev-parse HEAD
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
    if grep -Fq 'Call error: (1 0 #{make-mutex *top*:make-mutex} ())' "$log_dir/pb-control.log" &&
      grep -Fq 'exit_status=134' "$log_dir/pb-control.log"; then
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
native-thread)
  work="$root/build/$experiment/source"
  [[ -d "$work" ]] || {
    printf 'run bootquick first\n' >&2
    exit 1
  }
  log_run "$log_dir/native-thread-witness.log" nix shell "$root#i686-cc" nixpkgs#gnumake -c bash -c "cd '$work' && ./configure --threads --pbarch --32 --disable-x11 --disable-curses && make -j\"\${JOBS:-2}\" && file tpb32l/bin/tpb32l/scheme && ./tpb32l/bin/tpb32l/scheme --script '$root/experiments/$experiment/witness-thread.ss'"
  printf '%s NATIVE-THREAD-PASS target=tpb32l log=%s\n' "$experiment" "$log_dir/native-thread-witness.log"
  ;;
em-thread-node)
  work="$root/build/$experiment/source"
  [[ -x "$work/tpb32l/bin/tpb32l/scheme" ]] || {
    printf 'run native-thread first\n' >&2
    exit 1
  }
  "$work/tpb32l/bin/tpb32l/scheme" --script /dev/stdin <<SCHEME
(compile-file "$root/experiments/$experiment/witness-thread.ss" "$work/witness-thread.so")
(make-boot-file "$work/witness-thread.boot" '("petite") "$work/witness-thread.so")
SCHEME
  log_run "$log_dir/emscripten-thread-pool-1-build.log" nix develop -c bash -c "cd '$work' && ./configure --emscripten --threads --pbarch --emboot=witness-thread.boot --disable-x11 --disable-curses 'LDFLAGS+=-s PTHREAD_POOL_SIZE=1' && make -j\"\${JOBS:-2}\""
  log_run "$log_dir/node-thread-pool-1.log" nix develop -c bash -c "cd '$work/em-tpb32l/bin/tpb32l' && node scheme.js"
  printf '%s EM-THREAD-NODE-PASS target=tpb32l pool=1 log=%s\n' "$experiment" "$log_dir/node-thread-pool-1.log"
  ;;
host64-pack)
  work="$root/build/$experiment/source-host64"
  pack="$root/build/$experiment/pack-host64"
  rm -rf "$work" "$pack"
  nix develop -c bash -c 'cp -RL "$CHEZ_SOURCE"/. "$1"; chmod -R u+w "$1"' _ "$work"
  log_run "$log_dir/host64-build-and-bootquick.log" \
    bash -c "cd '$work' && ./configure --threads --pbarch --disable-x11 --disable-curses && make -j\"\${JOBS:-2}\" && make bootquick XM=tpb32l"
  log_run "$log_dir/host64-target-kernel.log" \
    nix shell "$root#i686-cc" nixpkgs#gnumake -c bash -c \
    'cd "$1" && ./configure --cross --force --threads --pbarch --32 --disable-x11 --disable-curses CC_FOR_BUILD=cc && make -j"${JOBS:-2}"' _ "$work"
  CHEZ_SRC="$work" "$root/../jolt/tools/cross-compile/make-pack.sh" tpb32l "$pack" |
    tee "$log_dir/host64-pack.log"
  sha256sum "$pack"/{xpatch,petite.boot,scheme.boot,libkernel.a} \
    >"$log_dir/host64-pack-hashes.txt"
  printf '%s HOST64-PACK-PASS host=tpb64l target=tpb32l pack=%s\n' "$experiment" "$pack"
  ;;
jolt-mint)
  work="$root/build/$experiment/source-host64"
  pack="$root/build/$experiment/pack-host64"
  jolt="$root/build/$experiment/jolt-patched"
  out="$root/build/$experiment/app-patched"
  patch_file="$root/experiments/$experiment/patches/jolt-tpb32l-word-size.patch"
  [[ -x "$work/tpb64l/bin/tpb64l/scheme" && -f "$pack/xpatch" ]] || {
    printf 'run host64-pack first\n' >&2
    exit 1
  }
  rm -rf "$jolt" "$out" "$out.build"
  nix develop -c bash -c 'cp -RL "$JOLT_SOURCE"/. "$1"; chmod -R u+w "$1"' _ "$jolt"
  nix develop -c patch --directory="$jolt" --strip=1 <"$patch_file"
  log_run "$log_dir/host64-hasheq-test.log" \
    make -C "$jolt" hasheq CHEZ="$work/tpb64l/bin/tpb64l/scheme"
  log_run "$log_dir/tpb32l-hash-test.log" \
    bash -c "cd '$jolt' && '$work/tpb32l/bin/tpb32l/scheme' --script test/chez/tpb32l-hash-test.ss"
  log_run "$log_dir/jolt-tpb32l-patched-mint.log" \
    nix shell "$root#i686-cc" -c bash -c \
    'export JOLT_CHEZ="$1/tpb64l/bin/tpb64l/scheme" JOLT_CHEZ_CSV="$1/tpb64l/boot/tpb64l" JOLT_TARGET_CC=gcc; "$2/bin/jolt" build -m app.exp014 -o "$3" --target tpb32l --target-pack "$4"' \
    _ "$work" "$jolt" "$out" "$pack"
  sha256sum "$out.build"/{flat.ss,flat.so,jolt.boot} "$patch_file" \
    >"$log_dir/jolt-tpb32l-patched-hashes.txt"
  if log_run "$log_dir/jolt-tpb32l-patched-native-run.log" "$out"; then
    printf '%s JOLT-NATIVE-UNEXPECTED-PASS\n' "$experiment" >&2
    exit 1
  else
    status=$?
    if [[ $status -eq 134 ]] &&
      grep -Fq 'protocol not supported (libffi unavailable)' \
        "$log_dir/jolt-tpb32l-patched-native-run.log"; then
      printf '%s JOLT-MINT-PASS target=tpb32l next=JOLT_FFI_CAPABILITY boot=%s\n' \
        "$experiment" "$out.build/jolt.boot"
      exit 0
    fi
    printf '%s JOLT-MINT-WRONG-FAILURE status=%s log=%s\n' \
      "$experiment" "$status" "$log_dir/jolt-tpb32l-patched-native-run.log" >&2
    exit "$status"
  fi
  ;;
jolt-node)
  work="$root/build/$experiment/source-libffi"
  pack="$root/build/$experiment/pack-libffi"
  ffi="$root/build/$experiment/libffi-em"
  jolt="$root/build/$experiment/jolt-libffi"
  out="$root/build/$experiment/app-libffi"
  chez_patch="$root/experiments/$experiment/patches/chez-emscripten-libffi.patch"
  jolt_patch="$root/experiments/$experiment/patches/jolt-tpb32l-word-size.patch"
  rm -rf "$work" "$pack" "$ffi" "$jolt" "$out" "$out.build"
  nix develop -c bash -c 'cp -RL "$CHEZ_SOURCE"/. "$1"; chmod -R u+w "$1"' _ "$work"
  nix develop -c patch --directory="$work" --strip=1 <"$chez_patch"
  log_run "$log_dir/libffi-host64-bootquick.log" \
    bash -c "cd '$work' && ./configure --threads --pbarch --disable-x11 --disable-curses && make -j\"\${JOBS:-2}\" && make bootquick XM=tpb32l"
  log_run "$log_dir/libffi-target-kernel.log" \
    nix shell "$root#i686-cc" nixpkgs#gnumake -c bash -c \
    'cd "$1" && ./configure --cross --force --threads --pbarch --32 --disable-x11 --disable-curses CC_FOR_BUILD=cc && make -j"${JOBS:-2}"' _ "$work"
  CHEZ_SRC="$work" "$root/../jolt/tools/cross-compile/make-pack.sh" tpb32l "$pack" |
    tee "$log_dir/libffi-pack.log"

  mkdir -p "$ffi/src"
  curl -fsSL https://github.com/libffi/libffi/releases/download/v3.5.2/libffi-3.5.2.tar.gz \
    -o "$ffi/libffi.tar.gz"
  printf '%s  %s\n' \
    f3a3082a23b37c293a4fcd1053147b371f2ff91fa7ea1b2a52e335676bac82dc \
    "$ffi/libffi.tar.gz" | sha256sum -c -
  tar -xf "$ffi/libffi.tar.gz" -C "$ffi/src" --strip-components=1
  mkdir "$ffi/src/build"
  log_run "$log_dir/libffi-em-build.log" nix develop -c bash -c '
    set -euo pipefail
    cd "$1/src/build"
    flags="-pthread -Wcast-function-type"
    CFLAGS="$flags" CPPFLAGS="$flags" LDFLAGS="$flags" \
      emconfigure ../configure --host=wasm32-unknown-emscripten \
        --prefix="$1/install" --enable-static --disable-shared \
        --disable-docs --disable-multi-os-directory
    emmake make -j"${JOBS:-2}"
    make install
  ' _ "$ffi"

  nix develop -c bash -c 'cp -RL "$JOLT_SOURCE"/. "$1"; chmod -R u+w "$1"' _ "$jolt"
  nix develop -c patch --directory="$jolt" --strip=1 <"$jolt_patch"
  log_run "$log_dir/tpb32l-full-hasheq-test.log" \
    bash -c "cd '$jolt' && '$work/tpb32l/bin/tpb32l/scheme' --script test/chez/hasheq-test.ss"
  log_run "$log_dir/libffi-jolt-native-expected.log" \
    env JOLT_CHEZ="$work/tpb64l/bin/tpb64l/scheme" \
    JOLT_CHEZ_CSV="$work/tpb64l/boot/tpb64l" "$jolt/bin/jolt" run -m app.exp014
  log_run "$log_dir/libffi-jolt-mint.log" \
    nix shell "$root#i686-cc" -c bash -c \
    'export JOLT_CHEZ="$1/tpb64l/bin/tpb64l/scheme" JOLT_CHEZ_CSV="$1/tpb64l/boot/tpb64l" JOLT_TARGET_CC=gcc; "$2/bin/jolt" build -m app.exp014 -o "$3" --target tpb32l --target-pack "$4"' \
    _ "$work" "$jolt" "$out" "$pack"
  log_run "$log_dir/libffi-jolt-em-build.log" nix develop -c bash -c '
    set -euo pipefail
    cd "$1"
    CPPFLAGS="-I$2/install/include" LDFLAGS="-L$2/install/lib -s PTHREAD_POOL_SIZE=1" \
      ./configure --emscripten --threads --pbarch --enable-libffi \
        --emboot="$3" --disable-x11 --disable-curses
    make -j"${JOBS:-2}"
  ' _ "$work" "$ffi" "$out.build/jolt.boot"
  log_run "$log_dir/libffi-jolt-node.log" \
    nix develop -c bash -c 'cd "$1/em-tpb32l/bin/tpb32l" && node scheme.js' _ "$work"
  grep -v '^warning: Git tree' "$log_dir/libffi-jolt-node.log" | head -n 4 >"$log_dir/libffi-jolt-node-output.txt"
  head -n 4 "$log_dir/libffi-jolt-native-expected.log" >"$log_dir/libffi-jolt-native-output.txt"
  diff -u "$log_dir/libffi-jolt-native-output.txt" "$log_dir/libffi-jolt-node-output.txt"
  grep -Fxq 'EXP-014-JOLT-COMPLETE' "$log_dir/libffi-jolt-node-output.txt"
  sha256sum "$jolt_patch" "$chez_patch" "$out.build"/{flat.ss,flat.so,jolt.boot} \
    "$work/em-tpb32l/bin/tpb32l"/{scheme.js,scheme.wasm,scheme.data} \
    >"$log_dir/libffi-jolt-hashes.txt"
  printf '%s JOLT-NODE-PASS target=tpb32l pool=1 log=%s\n' \
    "$experiment" "$log_dir/libffi-jolt-node.log"
  ;;
*) usage ;;
esac
