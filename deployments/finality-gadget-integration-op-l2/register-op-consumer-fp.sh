#!/bin/bash
set -euo pipefail

# create FP for the consumer chain
echo "Creating OP consumer finality provider..."
OP_FP_EOTS_PK_HEX=$(docker exec consumer-finality-provider /bin/sh -c "
    /bin/fpd create-finality-provider \
    --key-name $OP_FP_KEY_NAME \
    --chain-id $CONSUMER_ID \
    --moniker $OP_FP_MONIKER" | jq -r '.btc_pk_hex')
echo "OP_FP_EOTS_PK_HEX: $OP_FP_EOTS_PK_HEX"
echo
sleep 5

echo "Registering OP consumer finality provider..."
docker exec consumer-finality-provider /bin/sh -c "
    /bin/fpd register-finality-provider $OP_FP_EOTS_PK_HEX"
echo
sleep 5

# Get the public keys of the OP consumer FP
echo "Created OP consumer finality provider"
OP_FP_BTC_PK=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond query btcstkconsumer \
    finality-providers $CONSUMER_ID \
    --output json" | jq -r '.finality_providers[].btc_pk')
echo "BTC PK of OP consumer finality providers: $OP_FP_BTC_PK"
echo