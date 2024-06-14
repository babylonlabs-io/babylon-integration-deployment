#!/bin/bash

BBN_CHAIN_ID="chain-test"
CONSUMER_NAME="test-consumer"
CONSUMER_DESC="test-consumer-description"

# Wait until the IBC channels are ready
echo "Waiting for IBC channels to be ready..."
while true; do
    # Fetch the port ID and channel ID from the Consumer IBC channel list
    channelInfoJson=$(docker exec ibcsim-bcd /bin/sh -c "bcd query ibc channel channels -o json")

    # Check if there are any channels available
    channelsLength=$(echo $channelInfoJson | jq -r '.channels | length')
    if [ "$channelsLength" -gt 0 ]; then
        portId=$(echo $channelInfoJson | jq -r '.channels[0].port_id')
        channelId=$(echo $channelInfoJson | jq -r '.channels[0].channel_id')
        echo "Fetched port ID: $portId"
        echo "Fetched channel ID: $channelId"
        break
    else
        echo "No channels found, retrying in 10 seconds..."
        sleep 10
    fi
done

# Fetch the client ID from the IBC channel client-state query using the fetched port ID and channel ID
clientStateJson=$(docker exec ibcsim-bcd /bin/sh -c "bcd query ibc channel client-state $portId $channelId -o json")
CZ_CONSUMER_ID=$(echo $clientStateJson | jq -r '.client_id')

# The IBC client ID is the consumer ID
echo "Fetched IBC client ID, this will be used as consumer ID to register consumer on Babylon: $CZ_CONSUMER_ID"

sleep 10

# register a consumer chain
echo "Registering a consumer chain"
docker exec babylondnode0 /bin/sh -c "/bin/babylond --home /babylondhome tx btcstkconsumer register-consumer \"$CZ_CONSUMER_ID\" $CONSUMER_NAME $CONSUMER_DESC --from test-spending-key --fees 2ubbn -y --chain-id $BBN_CHAIN_ID --keyring-backend test"
echo "Registered a consumer chain with consumer ID $CZ_CONSUMER_ID"

# create FP for Babylon
echo ""
echo "Create 1 Bitcoin finality provider"
docker exec finality-provider /bin/sh -c "
    BTC_PK=\$(/bin/fpcli cfp --key-name finality-provider0 \
        --chain-id $BBN_CHAIN_ID \
        --moniker \"Babylon finality provider 0\" | jq -r .btc_pk_hex ); \
    /bin/fpcli rfp --btc-pk \$BTC_PK
"

# Get the public keys of the Babylon finality providers
echo "Created 1 Babylon finality provider"
bbn_btc_pk=$(docker exec btc-staker /bin/sh -c '/bin/stakercli dn bfp | jq -r ".finality_providers[].bitcoin_public_Key"')
echo "BTC PK of Babylon finality provider: $bbn_btc_pk"

# create FPs for the consumer chain
NUM_CZ_FPs=3
echo ""
echo "Creating $NUM_CZ_FPs consumer chain finality providers"
for idx in $(seq 1 $((NUM_CZ_FPs))); do
    docker exec finality-provider /bin/sh -c "
        BTC_PK=\$(/bin/fpcli cfp --key-name finality-provider$idx \
           --chain-id \"$CZ_CONSUMER_ID\" \
            --moniker \"Finality Provider $idx\" | jq -r .btc_pk_hex ); \
        /bin/fpcli rfp --btc-pk \$BTC_PK
    "
done
echo "Created $NUM_CZ_FPs consumer chain finality providers"

# Get the public keys of the consumer chain finality providers
cz_btc_pks=$(docker exec babylondnode0 /bin/sh -c "/bin/babylond query btcstkconsumer finality-providers \"$CZ_CONSUMER_ID\" --output json" | jq -r ".finality_providers[].btc_pk")
echo ""
echo "BTC PK of consumer chain finality providers: $cz_btc_pks"

# Make BTC delegations to the finality providers
echo ""
echo "Make a delegation to each of the finality providers from a dedicated BTC address"
sleep 10
# Get the available BTC addresses for delegations
delAddrs=($(docker exec btc-staker /bin/sh -c '/bin/stakercli dn list-outputs | jq -r ".outputs[].address" | sort | uniq'))
i=0
for cz_btc_pk in $cz_btc_pks
do
    stakingTime=500

    echo "Delegating 1 million Satoshis from BTC address ${delAddrs[i]} to Finality Provider with CZ finality provider $cz_btc_pk and Babylon finality provider $bbn_btc_pk for $stakingTime BTC blocks";

    btcTxHash=$(docker exec btc-staker /bin/sh -c \
        "/bin/stakercli dn stake --staker-address ${delAddrs[i]} --staking-amount 1000000 --finality-providers-pks $bbn_btc_pk --finality-providers-pks $cz_btc_pk --staking-time $stakingTime | jq -r '.tx_hash'")
    echo "Delegation was successful; staking tx hash is $btcTxHash"
    i=$((i+1))
done
echo "Made a delegation to each of the finality providers"

# Query babylon and check if the delegations are active
# NOTE: avoid querying finality provider as it might be down
# https://github.com/babylonchain/finality-provider/issues/327
echo ""
echo "Wait a few minutes for the delegations to become active..."
while true; do
    # Get the active delegations count from Babylon
    activeDelegations=$(docker exec babylondnode0 /bin/sh -c 'babylond q btcstaking btc-delegations active -o json | jq ".btc_delegations | length"')

    echo "Active delegations count in Babylon: $activeDelegations"

    if [ "$activeDelegations" -eq "$NUM_CZ_FPs" ]; then
        echo "All delegations have become active"
        break
    else
        sleep 10
    fi
done

# Query contract state and check the count of finality providers
echo ""
echo "Check if contract has stored the finality providers..."
while true; do
    # Get the contract address from the list-contract-by-code query
    contractAddress=$(docker exec ibcsim-bcd /bin/sh -c 'bcd q wasm list-contract-by-code 2 -o json | jq -r ".contracts[0]"')

    # Get the finality providers count from the contract state
    finalityProvidersCount=$(docker exec ibcsim-bcd /bin/sh -c "bcd q wasm contract-state smart $contractAddress '{\"finality_providers\":{}}' -o json | jq '.data.fps | length'")

    echo "Finality provider count in contract store: $finalityProvidersCount"

    if [ "$finalityProvidersCount" -eq "$NUM_CZ_FPs" ]; then
        echo "The number of finality providers in contract matches the expected count."
        break
    else
        sleep 10
    fi
done

# Query contract state and check the count of delegations
echo ""
echo "Check if contract has stored the delegations..."
while true; do
    # Get the delegations count from the contract state
    delegationsCount=$(docker exec ibcsim-bcd /bin/sh -c "bcd q wasm contract-state smart $contractAddress '{\"delegations\":{}}' -o json | jq '.data.delegations | length'")

    echo "Delegations count in contract store: $delegationsCount"

    if [ "$delegationsCount" -eq "$NUM_CZ_FPs" ]; then
        echo "The number of delegations in contract matches the expected count."
        break
    else
        sleep 10
    fi
done