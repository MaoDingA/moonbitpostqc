#!/usr/bin/env bash
#
# MoonPostQC competition preflight gate.
#
# The current MoonBit CLI does not accept --deny-warn on `moon fmt` or
# `moon info`. This script uses the supported strict equivalents:
# - `moon fmt --check` for formatting
# - `moon check --fmt --deny-warn` for formatter diagnostics as errors
# - `moon info` plus `git diff --exit-code -- .` for generated interface sync
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

run() {
  echo ""
  echo "+ $*"
  "$@"
}

echo "MoonPostQC competition preflight"

run moon --version
run moon fmt --check
run moon check --fmt --deny-warn
run moon info
run git diff --exit-code -- .
run moon check --target native --deny-warn
run moon check --target wasm-gc --deny-warn
run moon test --target native --deny-warn
run moon test --target wasm-gc --deny-warn
run ./scripts/e2e-acceptance.sh

echo ""
echo "Competition preflight passed."
