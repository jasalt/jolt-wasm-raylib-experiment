#!/usr/bin/env bash
set -euo pipefail
./scripts/bootstrap
./scripts/test-native
./scripts/nrepl-smoke
