#!/bin/bash
set -euo pipefail

# Checks if at least two arguments are provided: consumer_id and activated_height
if [ $# -lt 2 ]; then
    echo "Usage: $0 <consumer_id> <activated_height> [admin]"
    exit 1
fi

HOME_DIR="/babylondhome"
KEY_NAME="test-spending-key"
CHAIN_ID="chain-test"
WASM_FILE="artifacts/op_finality_gadget.wasm"
LABEL="op_finality_gadget"

CONSUMER_ID="$1"
ACTIVATED_HEIGHT="$2"
# Sets the ADMIN to the third argument if provided, otherwise uses the DEPLOYER_ADDRESS
DEPLOYER_ADDRESS=$(babylond keys show -a $KEY_NAME --keyring-backend test --home $HOME_DIR)
ADMIN="${3:-$DEPLOYER_ADDRESS}"

echo "Upload the CW contract code"
TX_HASH=$(babylond tx wasm store $WASM_FILE \
        --from $DEPLOYER_ADDRESS \
        --keyring-backend test \
        --home $HOME_DIR \
        --chain-id $CHAIN_ID \
        --gas-prices 0.2ubbn --gas auto --gas-adjustment 1.3 \
        -o json -y | jq -r '.txhash')

sleep 2

echo "Query the code_id with tx hash: $TX_HASH"
CODE_ID=$(babylond query tx $TX_HASH \
        --home $HOME_DIR \
        --chain-id $CHAIN_ID \
        -o json | jq -r '.events[] | select(.type == "store_code") | .attributes[] | select(.key == "code_id") | .value')

JSON_VALUE=$(printf '{"admin":"%s","consumer_id":"%s","activated_height":%d,"is_enabled":true}' "$ADMIN" "$CONSUMER_ID" "$ACTIVATED_HEIGHT")
echo "Instantiate the CW contract with code_id: $CODE_ID and the value: $JSON_VALUE"
babylond tx wasm instantiate $CODE_ID $JSON_VALUE \
    --label $LABEL --admin $ADMIN \
    --from $DEPLOYER_ADDRESS \
    --keyring-backend test \
    --home $HOME_DIR \
    --chain-id $CHAIN_ID \
    --gas-prices 0.2ubbn --gas auto --gas-adjustment 1.3 \
    -o json -y

sleep 2

echo "Query the CW contract config to verify the CW contract is instantiated correctly"
CONTRACT_ADDRESS=$(babylond query wasm list-contract-by-code $CODE_ID \
        --chain-id $CHAIN_ID \
        --home $HOME_DIR \
        -o json | jq -r '.contracts[]')
QUERY_CONFIG='{"config":{}}'
babylond query wasm contract-state smart $CONTRACT_ADDRESS $QUERY_CONFIG \
    --home $HOME_DIR \
    --chain-id $CHAIN_ID \
    -o json
