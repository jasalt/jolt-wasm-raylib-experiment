#!/usr/bin/env bash
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
"$root/scripts/chez-wasm-build"
"$root/scripts/chez-wasm-node"
