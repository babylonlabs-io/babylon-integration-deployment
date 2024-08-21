#!/bin/bash
set -euo pipefail

# Go to the Babylon CW contracts directory
BABYLON_CONTRACT_DIR=$1
echo "BABYLON_CONTRACT_DIR: $BABYLON_CONTRACT_DIR"
cd $BABYLON_CONTRACT_DIR

# generate CW contract wasm file
echo "Building the CW contract..."
cargo install cargo-run-script
cargo build
cargo run-script optimize 2>/dev/null

WASM_FILE="$BABYLON_CONTRACT_DIR/artifacts/op_finality_gadget.wasm"
# check if wasm file exists and is not empty
if [ -s "$WASM_FILE" ]; then
    echo "$WASM_FILE generated"
else
    echo "$WASM_FILE not generated or is empty"
    exit 1
fi
echo