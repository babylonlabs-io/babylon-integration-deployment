#!/bin/bash
set -euo pipefail

# For signet, load environment variables from .env file
echo "Load environment variables from .env file..."
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

if [ -z "$(echo ${CONSUMER_ID})" ]; then
    echo "Error: CONSUMER_ID environment variable is not set"
    exit 1
fi
echo "Environment variables loaded successfully"
echo

# Create BTC delegation to the finality providers
echo "Create BTC delegation to Babylon and OP consumer finality providers from a dedicated BTC address"
# DELEGATION_ADDR=$(docker exec btc-staker /bin/sh -c "
#     /bin/stakercli daemon list-outputs" | jq -r '.outputs[].address' | sort | uniq)
DELEGATION_ADDR=$(docker exec bitcoindsim /bin/sh -c "
    bitcoin-cli -${BITCOIN_NETWORK} -rpcuser=rpcuser -rpcpassword=rpcpass -rpcwallet=btcstaker listunspent" | jq -r '.[].address' | sort | uniq)
BBN_FP_BTC_PK=$(docker exec btc-staker /bin/sh -c "
    /bin/stakercli daemon babylon-finality-providers" | jq -r '.finality_providers[].bitcoin_public_Key')
OP_FP_BTC_PK=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond query btcstkconsumer \
    finality-providers $CONSUMER_ID \
    --output json" | jq -r '.finality_providers[].btc_pk')
STAKING_TIME=10000
STAKING_AMOUNT=10000
echo "Delegating $STAKING_AMOUNT Satoshis from BTC address $DELEGATION_ADDR to Babylon finality provider $BBN_FP_BTC_PK and OP consumer finality provider $OP_FP_BTC_PK for $STAKING_TIME BTC blocks"
BTC_DEL_TX_HASH=$(docker exec btc-staker /bin/sh -c "
    /bin/stakercli daemon stake \
    --staker-address $DELEGATION_ADDR \
    --staking-amount $STAKING_AMOUNT \
    --finality-providers-pks $BBN_FP_BTC_PK \
    --finality-providers-pks $OP_FP_BTC_PK \
    --staking-time $STAKING_TIME" | jq -r '.tx_hash')
echo "Delegation was successful; staking tx hash is $BTC_DEL_TX_HASH"
echo

# Query babylon and check if the delegation is active
echo "Wait a few minutes for the delegation to become active..."
while true; do
    # Get the active delegations count from Babylon
    ACTIVE_DELEGATIONS_COUNT=$(docker exec babylondnode0 /bin/sh -c "
        /bin/babylond query btcstaking btc-delegations active -o json" | jq '.btc_delegations | length')

    echo "Active delegations count in Babylon: $ACTIVE_DELEGATIONS_COUNT"

    if [ "$ACTIVE_DELEGATIONS_COUNT" -eq 1 ]; then
        echo "BTC delegation has become active at $(date +"%Y-%m-%d %H:%M:%S")"
        break
    else
        sleep 10
    fi
done
echo