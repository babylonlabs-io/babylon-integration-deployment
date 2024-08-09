#!/bin/sh
set -euo pipefail

### Babylon
export BABYLON_HOME_DIR="/babylondhome"
export TEST_SPENDING_KEY_NAME="test-spending-key"
export BABYLON_CHAIN_ID="chain-test"
# Get the container ID of babylondnode0
export BABYLON_CONTAINER_ID=$(docker ps -qf "name=babylondnode0")

### CW contract
# TODO: use the L2 ChainId of op chain
export CONSUMER_ID="op-stack-l2-901"
export ACTIVATED_HEIGHT="12345"
export CW_ADMIN="bbn1kghr9hekuxj0tqa9pfnpxym4x6z0k0x77qxa79"
export CW_LABEL="op_finality_gadget"
export WASM_FILE_LOCAL="artifacts/op_finality_gadget.wasm"
export WASM_FILE_CONTAINER="/home/babylon/op_finality_gadget.wasm"

### OP consumer
export CONSUMER_NAME="Snapchain Tohma"
export CONSUMER_DESC="An OP Stack demonet that integrates with Babylon finality gadget"