#!/bin/bash
set -euo pipefail

# Get all registered consumer IDs and store them in an array
# TODO: this adds another coupling between our system and the Babylon chain.
# we should use RPC calls
CONSUMER_IDS=($(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond query btcstkconsumer registered-consumers \
    --home $BABYLON_HOME_DIR \
    --chain-id $BABYLON_CHAIN_ID \
    -o json" | jq -r '.consumer_ids[]'))

# Check if the OP consumer chain is already registered
if [[ "${CONSUMER_IDS[@]}" =~ "${CONSUMER_ID}" ]]; then
    echo "OP consumer chain already registered with ID: $CONSUMER_ID"
    exit 0
fi

# Register op consumer chain
echo "Registering OP consumer chain..."
REGISTER_TX_HASH=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond tx btcstkconsumer register-consumer '$CONSUMER_ID' '$CONSUMER_NAME' '$CONSUMER_DESC'  \
    --home $BABYLON_HOME_DIR \
    --chain-id $BABYLON_CHAIN_ID \
    --from $TEST_SPENDING_KEY_NAME \
    --keyring-backend test \
    --gas-prices 0.2ubbn \
    --gas auto \
    --gas-adjustment 2 \
    -o json -y" | jq -r '.txhash')
echo "REGISTER_TX_HASH: $REGISTER_TX_HASH"
echo
sleep 5

### Query all consumer chains to verify the OP consumer chain is registered successfully
echo "Query all consumer chains to verify the OP consumer chain is registered successfully"
REGISTERED_CONSUMERS=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond query btcstkconsumer registered-consumers \
    --home $BABYLON_HOME_DIR \
    --chain-id $BABYLON_CHAIN_ID \
    -o json")
echo "REGISTERED_CONSUMERS: $REGISTERED_CONSUMERS"
echo