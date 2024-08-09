#!/bin/bash
set -euo pipefail

### Checks if at least three arguments are provided: consumer_id and activated_height
if [ $# -lt 3 ]; then
    echo "Usage: $0 <consumer_id> <activated_height> <admin>"
    exit 1
fi
CONSUMER_ID="$1"
ACTIVATED_HEIGHT="$2"
ADMIN="$3"
echo "CONSUMER_ID: $1"
echo "ACTIVATED_HEIGHT: $2"
echo "ADMIN: $3"
echo

### Define constants
HOME_DIR="/babylondhome"
TEST_SPENDING_KEY_NAME="test-spending-key"
CHAIN_ID="chain-test"
WASM_FILE_LOCAL="artifacts/op_finality_gadget.wasm"
WASM_FILE_CONTAINER="/home/babylon/op_finality_gadget.wasm"
LABEL="op_finality_gadget"
# Get the container ID of babylondnode0
CONTAINER_ID=$(docker ps -qf "name=babylondnode0")

### Store the CW contract code
# Copy the wasm file into the container
docker cp $WASM_FILE_LOCAL $CONTAINER_ID:$WASM_FILE_CONTAINER
echo
echo "Storing the CW contract code..."
STORE_CODE_TX_HASH=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond tx wasm store $WASM_FILE_CONTAINER \
    --home $HOME_DIR \
    --from $TEST_SPENDING_KEY_NAME \
    --chain-id $CHAIN_ID \
    --keyring-backend test \
    --gas-prices 0.2ubbn \
    --gas auto \
    --gas-adjustment 1.3 \
    -o json -y" | jq -r '.txhash')
echo "STORE_CODE_TX_HASH: $STORE_CODE_TX_HASH"
echo
# TODO: add a for loop to check if the code is stored
sleep 7

### Query the code_id using the tx hash
echo "Querying the code_id using the tx hash..."
CODE_ID=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond query tx $STORE_CODE_TX_HASH \
    --home $HOME_DIR \
    --chain-id $CHAIN_ID \
    -o json" \
    | jq -r '.events[] | select(.type == "store_code") | .attributes[] | select(.key == "code_id") | .value')
echo "CODE_ID: $CODE_ID"
echo

### Instantiate the CW contract
JSON_VALUE=$(printf '{"admin":"%s","consumer_id":"%s","activated_height":%d,"is_enabled":true}' "$ADMIN" "$CONSUMER_ID" "$ACTIVATED_HEIGHT")
echo "Instantiating the CW contract with arguments: $JSON_VALUE ..."
CREATE_CONTRACT_TX_HASH=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond tx wasm instantiate $CODE_ID '$JSON_VALUE' \
    --label $LABEL \
    --admin $ADMIN \
    --from $TEST_SPENDING_KEY_NAME \
    --keyring-backend test \
    --home $HOME_DIR \
    --chain-id $CHAIN_ID \
    --gas-prices 0.2ubbn --gas auto --gas-adjustment 1.3 \
    -o json -y" | jq -r '.txhash')
echo "CREATE_CONTRACT_TX_HASH: $CREATE_CONTRACT_TX_HASH"
echo
sleep 5

### Query the CW contract config to verify the CW contract is instantiated correctly
echo "Query the CW contract config to verify the CW contract is instantiated correctly"
CONTRACT_ADDRESS=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond query wasm list-contract-by-code $CODE_ID \
    --chain-id $CHAIN_ID \
    --home $HOME_DIR \
    -o json" | jq -r '.contracts[]')
echo "Contract address: $CONTRACT_ADDRESS"
QUERY_CONFIG='{"config":{}}'
CONTRACT_CONFIG=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond query wasm contract-state smart $CONTRACT_ADDRESS '$QUERY_CONFIG' \
    --home $HOME_DIR \
    --chain-id $CHAIN_ID \
    -o json")
echo "Contract config: $CONTRACT_CONFIG"