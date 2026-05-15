#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
moon build wasm_demo/core --target wasm-gc --release
mkdir -p wasm-demo/public
cp _build/wasm-gc/release/build/wasm_demo/core/core.wasm \
  wasm-demo/public/moonpost_qc.wasm

echo "Built wasm-demo/public/moonpost_qc.wasm"
