#!/bin/bash
set -euo pipefail

# check if the OP consumer FP already exists
EXISTING_OP_FP_MONIKER=$(docker exec consumer-finality-provider /bin/sh \
    -c "/bin/fpd list-finality-providers" \
    | jq '.finality_providers[0].description.moniker')
EXISTING_OP_FP_EOTS_PK_HEX=$(docker exec consumer-finality-provider /bin/sh \
    -c "/bin/fpd list-finality-providers" \
    | jq -r '.finality_providers[0].btc_pk_hex')
if [ "$EXISTING_OP_FP_MONIKER" == "$OP_FP_MONIKER" ]; then
    echo "OP consumer finality provider already exists with \
moniker: $EXISTING_OP_FP_MONIKER and \
EOTS PK: $EXISTING_OP_FP_EOTS_PK_HEX"
    exit 0
fi

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