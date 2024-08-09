#!/bin/bash
set -euo pipefail

### Checks if at least two arguments are provided: consumer_id and consumer_name
if [ $# -lt 2 ]; then
    echo "Usage: $0 <consumer_id> <consumer_name> [consumer_description]"
    exit 1
fi
CONSUMER_ID="$1"
CONSUMER_NAME="$2"
DEFAULT_DESCRIPTION="An OP Stack demonet that integrates with Babylon finality gadget"
CONSUMER_DESC="${3:-$DEFAULT_DESCRIPTION}"
echo "consumer-id: $CONSUMER_ID"
echo "consumer_name: $CONSUMER_NAME"
echo "consumer_description: $CONSUMER_DESC"
echo

### Define constants
HOME_DIR="/babylondhome"
TEST_SPENDING_KEY_NAME="test-spending-key"
CHAIN_ID="chain-test"

# Get the container ID of babylondnode0
CONTAINER_ID=$(docker ps -qf "name=babylondnode0")

# Register op consumer chain
echo "Registering OP consumer chain..."
REGISTER_TX_HASH=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond tx btcstkconsumer register-consumer '$CONSUMER_ID' '$CONSUMER_NAME' '$CONSUMER_DESC'  \
    --home $HOME_DIR \
    --from $TEST_SPENDING_KEY_NAME \
    --chain-id $CHAIN_ID \
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
    --home $HOME_DIR \
    --chain-id $CHAIN_ID \
    -o json")
echo "REGISTERED_CONSUMERS: $REGISTERED_CONSUMERS"