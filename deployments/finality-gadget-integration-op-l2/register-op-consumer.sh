#!/bin/bash
set -euo pipefail

# Get the container ID of babylondnode0
BABYLON_CONTAINER_ID=$(docker ps -qf "name=babylondnode0")

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