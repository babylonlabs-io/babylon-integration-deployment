#!/bin/bash
set -euo pipefail

# Copy the wasm file into the container
BABYLON_CONTRACT_DIR=$1
WASM_FILE_LOCAL="$BABYLON_CONTRACT_DIR/artifacts/op_finality_gadget.wasm"
echo "wasm file: $WASM_FILE_LOCAL, $BABYLON_HOME_DIR"
docker cp $WASM_FILE_LOCAL babylondnode0:$BABYLON_HOME_DIR
echo

# Store the CW contract code
echo "Storing the CW contract code..."
STORE_CODE_TX_HASH=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond tx wasm store $BABYLON_HOME_DIR \
    --home $BABYLON_HOME_DIR \
    --chain-id $BABYLON_CHAIN_ID \
    --from $TEST_SPENDING_KEY_NAME \
    --keyring-backend test \
    --gas-prices 0.2ubbn \
    --gas auto \
    --gas-adjustment 1.3 \
    -o json -y" | jq -r '.txhash')
echo "STORE_CODE_TX_HASH: $STORE_CODE_TX_HASH"
echo
# TODO: add a for loop to check if the code is stored
sleep 7

# Query the code_id using the tx hash
echo "Querying the code_id using the tx hash..."
CODE_ID=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond query tx $STORE_CODE_TX_HASH \
    --home $BABYLON_HOME_DIR \
    --chain-id $BABYLON_CHAIN_ID \
    -o json" \
    | jq -r '.events[] | select(.type == "store_code") | .attributes[] | select(.key == "code_id") | .value')
echo "CODE_ID: $CODE_ID"
echo

# Instantiate the CW contract
JSON_VALUE=$(printf '{"admin":"%s","consumer_id":"%s","activated_height":%d,"is_enabled":true}' "$CW_ADMIN" "$CONSUMER_ID" "$ACTIVATED_HEIGHT")
echo "Instantiating the CW contract with arguments: $JSON_VALUE ..."
CREATE_CONTRACT_TX_HASH=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond tx wasm instantiate $CODE_ID '$JSON_VALUE' \
    --label $CW_LABEL \
    --admin $CW_ADMIN \
    --home $BABYLON_HOME_DIR \
    --chain-id $BABYLON_CHAIN_ID \
    --from $TEST_SPENDING_KEY_NAME \
    --keyring-backend test \
    --gas-prices 0.2ubbn --gas auto --gas-adjustment 1.3 \
    -o json -y" | jq -r '.txhash')
echo "CREATE_CONTRACT_TX_HASH: $CREATE_CONTRACT_TX_HASH"
echo
sleep 7

# Query the CW contract config to verify the CW contract is instantiated correctly
echo "Query the CW contract config to verify the CW contract is instantiated correctly"
CONTRACT_ADDRESS=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond query wasm list-contract-by-code $CODE_ID \
    --home $BABYLON_HOME_DIR \
    --chain-id $BABYLON_CHAIN_ID \
    -o json" | jq -r '.contracts[]')
echo "Contract address: $CONTRACT_ADDRESS"
QUERY_CONFIG='{"config":{}}'
CONTRACT_CONFIG=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond query wasm contract-state smart $CONTRACT_ADDRESS '$QUERY_CONFIG' \
    --home $BABYLON_HOME_DIR \
    --chain-id $BABYLON_CHAIN_ID \
    -o json")
echo "Contract config: $CONTRACT_CONFIG"
echo

echo "Updating OP finality gadget config file with the deployed CW contract address..."
OP_FG_CONF_FILE=".testnets/finality-gadget/opfgd.toml"
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS version
    sed -i '' "s|FGContractAddress = .*|FGContractAddress = \"$CONTRACT_ADDRESS\"|" $OP_FG_CONF_FILE
else
    # Linux version
    sed -i "s|FGContractAddress = .*|FGContractAddress = \"$CONTRACT_ADDRESS\"|" $OP_FG_CONF_FILE
fi
FG_CONTRACT_ADDRESS=$(grep FGContractAddress $OP_FG_CONF_FILE | awk '{print $3}' | tr -d '"')
if [[ "$FG_CONTRACT_ADDRESS" == "$CONTRACT_ADDRESS" ]]; then
    echo "Updated $OP_FG_CONF_FILE FGContractAddress: $FG_CONTRACT_ADDRESS"
else
    echo "Failed to update $OP_FG_CONF_FILE FGContractAddress"
    exit 1
fi
echo

echo "Updating OP FP config file with the deployed CW contract address..."
OP_FP_CONF_FILE=".testnets/consumer-finality-provider/fpd.conf"
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS version
    sed -i '' "s|OPFinalityGadgetAddress = .*|OPFinalityGadgetAddress = $CONTRACT_ADDRESS|" $OP_FP_CONF_FILE
else
    # Linux version
    sed -i "s|OPFinalityGadgetAddress = .*|OPFinalityGadgetAddress = $CONTRACT_ADDRESS|" $OP_FP_CONF_FILE
fi
OP_FINALITY_GADGET_ADDRESS=$(grep OPFinalityGadgetAddress $OP_FP_CONF_FILE | awk '{print $3}')
if [[ "$OP_FINALITY_GADGET_ADDRESS" == "$CONTRACT_ADDRESS" ]]; then
    echo "Updated $OP_FP_CONF_FILE OPFinalityGadgetAddress: $OP_FINALITY_GADGET_ADDRESS"
else
    echo "Failed to update $OP_FP_CONF_FILE OPFinalityGadgetAddress"
    exit 1
fi
echo