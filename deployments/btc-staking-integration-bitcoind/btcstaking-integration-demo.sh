#!/bin/bash

BBN_CHAIN_ID="chain-test"

echo "Waiting for relayer to recover keys..."
while true; do
    # Check if both keys are recovered by querying them
    BABYLON_ADDRESS=$(docker exec ibcsim-bcd /bin/sh -c "rly --home /data/relayer keys list babylon 2>/dev/null" | cut -d' ' -f3)
    BCD_ADDRESS=$(docker exec ibcsim-bcd /bin/sh -c "rly --home /data/relayer keys list bcd 2>/dev/null" | cut -d' ' -f3)

    if [ -n "$BABYLON_ADDRESS" ] && [ -n "$BCD_ADDRESS" ]; then
        echo "Successfully recovered keys for both chains"
        break
    else
        echo "Waiting for key recovery... (babylon: $BABYLON_ADDRESS, bcd: $BCD_ADDRESS)"
        sleep 5
    fi
done

###############################
#    Create IBC Light Clients #
###############################

echo "Creating IBC light clients on Babylon and bcd"
docker exec ibcsim-bcd /bin/sh -c "rly --home /data/relayer tx clients bcd"
[ $? -eq 0 ] && echo "Created IBC light clients successfully!" || echo "Error creating IBC light clients"

sleep 10

# Query client ID registered in Babylon node, as consumer ID
echo "Querying client ID registered in Babylon node..."
CONSUMER_ID=$(docker exec babylondnode0 babylond query ibc client states -o json | jq -r '.client_states[0].client_id')
[ -n "$CONSUMER_ID" ] && echo "Found client ID: $CONSUMER_ID" || echo "Error: Could not find client ID"

########################################
#    Create IBC Channel for IBC transfer #
########################################

echo "Creating IBC channel for IBC transfer"
docker exec ibcsim-bcd /bin/sh -c "rly --home /data/relayer tx link bcd --src-port transfer --dst-port transfer --order unordered --version ics20-1"
[ $? -eq 0 ] && echo "Created IBC transfer channel successfully!" || echo "Error creating IBC transfer channel"

###############################
#    Register the consumer    #
###############################

echo "Registering the consumer"
docker exec babylondnode0 babylond tx btcstkconsumer register-consumer $CONSUMER_ID "consumer-name" "consumer-description" --from babylond --chain-id $BBN_CHAIN_ID -y

# The IBC client ID is the consumer ID
echo "Fetched IBC client ID, this will be used as consumer ID and automatically register in Babylon: $CONSUMER_ID"
while true; do
    # Consumer should be automatically registered in Babylon via IBC, query registered consumers
    REGISTERED_CONSUMER_IDS=$(docker exec babylondnode0 /bin/sh -c "/bin/babylond query btcstkconsumer registered-consumers -o json | jq -r '.consumer_ids'")

    # Check if there's exactly one consumer ID and it matches the expected CONSUMER_ID
    if [ $(echo $REGISTERED_CONSUMER_IDS | jq 'length') -eq 1 ] && [ $(echo $REGISTERED_CONSUMER_IDS | jq -r '.[0]') = "$CONSUMER_ID" ]; then
        echo "Verification successful: Exactly one consumer registered in Babylon with the expected ID."
        break
    else
        echo "Verification failed: Consumer ID not found in Babylon"
        echo "Expected consumer with ID: $CONSUMER_ID"
        echo "Found: $REGISTERED_CONSUMER_IDS"
        echo "Retrying in 10 seconds..."
        sleep 10
    fi
done

##############################################
#    Create IBC Channel for ZoneConcierge    #
##############################################

# Query contract address from ibcsim-bcd container
# TODO: query babylon module for getting the contract address
CONTRACT_ADDRESS=$(docker exec ibcsim-bcd /bin/sh -c 'bcd query wasm list-contract-by-code 1 -o json | jq -r ".contracts[0]"')
CONTRACT_PORT="wasm.$CONTRACT_ADDRESS"

# Create IBC channel for ZoneConcierge
echo "Creating IBC channel for zoneconcierge"
docker exec ibcsim-bcd /bin/sh -c "rly --home /data/relayer tx link bcd --src-port zoneconcierge --dst-port $CONTRACT_PORT --order ordered --version zoneconcierge-1"
[ $? -eq 0 ] && echo "Created zonecincierge IBC channel successfully!" || echo "Error creating zonecincierge IBC channel"

sleep 10

########################################
#    Start the relayer                  #
########################################

echo "Starting the relayer"
docker exec ibcsim-bcd /bin/sh -c "rly --home /data/relayer start bcd --debug-addr "" --flush-interval 30s"

# Wait until the IBC channels are ready
echo "Waiting for IBC channels to be ready..."
while true; do
    # Fetch the port ID and channel ID from the Consumer IBC channel list
    channelInfoJson=$(docker exec ibcsim-bcd /bin/sh -c "bcd query ibc channel channels -o json")

    # Check if there are any channels available
    channelsLength=$(echo $channelInfoJson | jq -r '.channels | length')
    if [ "$channelsLength" -gt 1 ]; then
        # Print all channel port/ids
        echo "Found channels:"
        echo "$channelInfoJson" | jq -r '.channels[] | "Port ID: \(.port_id), Channel ID: \(.channel_id)"'
        # Store second channel info for later use
        portId=$(echo "$channelInfoJson" | jq -r '.channels[1].port_id')
        channelId=$(echo "$channelInfoJson" | jq -r '.channels[1].channel_id')
        break
    else
        echo "Found only $channelsLength channels, retrying in 10 seconds..."
        sleep 10
    fi
done

echo "Integration between Babylon and bcd is ready!"
echo "Now we will try out BTC staking on the consumer chain..."

# Get the BTC staking contract address from the list-contract-by-code query
btcStakingContractAddr=$(docker exec ibcsim-bcd /bin/sh -c 'bcd q wasm list-contract-by-code 2 -o json | jq -r ".contracts[0]"')

# create FP for Babylon
echo ""
echo "Create 1 Babylon finality provider"
FP_KEYNAME="finality-provider"
docker exec finality-provider /bin/sh -c "
    BTC_PK=\$(/bin/fpd create-finality-provider --key-name $FP_KEYNAME \
        --chain-id $BBN_CHAIN_ID \
        --moniker \"Babylon finality provider 0\" | jq -r .btc_pk_hex ); \
    /bin/fpd register-finality-provider \$BTC_PK
"

# Get the public keys of the Babylon finality providers
echo "Created 1 Babylon finality provider"
bbn_btc_pk=$(docker exec btc-staker /bin/sh -c '/bin/stakercli dn bfp | jq -r ".finality_providers[].bitcoin_public_Key"')
echo "BTC PK of Babylon finality provider: $bbn_btc_pk"

# create FPs for the consumer chain
NUM_COMSUMER_FPS=1
CONSUMER_FP_KEYNAME="finality-provider"
echo ""
echo "Creating $NUM_COMSUMER_FPS consumer chain finality providers"
for idx in $(seq 1 $((NUM_COMSUMER_FPS))); do
    docker exec consumer-fp /bin/sh -c "
        BTC_PK=\$(/bin/fpd create-finality-provider --key-name $CONSUMER_FP_KEYNAME \
           --chain-id \"$CONSUMER_ID\" \
            --moniker \"Finality Provider $idx\" | jq -r .btc_pk_hex ); \
        /bin/fpd register-finality-provider \$BTC_PK
    "
done
echo "Created $NUM_COMSUMER_FPS consumer chain finality providers"

# Get the public keys of the consumer chain finality providers
CONSUMER_BTC_PKS=$(docker exec babylondnode0 /bin/sh -c "/bin/babylond query btcstkconsumer finality-providers \"$CONSUMER_ID\" --output json" | jq -r ".finality_providers[].btc_pk")
echo ""
echo "BTC PK of consumer chain finality providers: $CONSUMER_BTC_PKS"

# Query contract state and check the count of finality providers
echo ""
echo "Check if contract has stored the finality providers..."
while true; do
    # Get the finality providers count from the contract state
    finalityProvidersCount=$(docker exec ibcsim-bcd /bin/sh -c "bcd q wasm contract-state smart $btcStakingContractAddr '{\"finality_providers\":{}}' -o json | jq '.data.fps | length'")

    echo "Finality provider count in contract store: $finalityProvidersCount"

    if [ "$finalityProvidersCount" -eq "$NUM_COMSUMER_FPS" ]; then
        echo "The number of finality providers in contract matches the expected count."
        break
    else
        sleep 10
    fi
done

# ensure finality providers are committing public randomness
echo ""
echo "Ensuring all finality providers have committed public randomness..."
while true; do
    cnt=0
    for consumer_btc_pk in $CONSUMER_BTC_PKS; do
        pr_commit_info=$(docker exec ibcsim-bcd /bin/sh -c "bcd query wasm contract-state smart $btcStakingContractAddr '{\"last_pub_rand_commit\":{\"btc_pk_hex\":\"$consumer_btc_pk\"}}' -o json")
        if [[ "$(echo "$pr_commit_info" | jq '.data')" == *"null"* ]]; then
            echo "The finality provider $consumer_btc_pk hasn't committed any public randomness yet"
            sleep 10
        else
            echo "The finality provider $consumer_btc_pk has committed public randomness"
            cnt=$((cnt + 1))
        fi
    done
    if [ "$cnt" -eq $NUM_COMSUMER_FPS ]; then
        echo "All of $consumer_btc_pk finality providers have committed public randomness!"
        break
    fi
done

# Make BTC delegations to the finality providers
echo ""
echo "Make a delegation to each of the finality providers from a dedicated BTC address"
sleep 10
# Get the available BTC addresses for delegations
delAddrs=($(docker exec btc-staker /bin/sh -c '/bin/stakercli dn list-outputs | jq -r ".outputs[].address" | sort | uniq'))
i=0
for consumer_btc_pk in $CONSUMER_BTC_PKS; do
    stakingTime=10000

    echo "Delegating 1 million Satoshis from BTC address ${delAddrs[i]} to Finality Provider with CZ finality provider $consumer_btc_pk and Babylon finality provider $bbn_btc_pk for $stakingTime BTC blocks"

    btcTxHash=$(docker exec btc-staker /bin/sh -c \
        "/bin/stakercli dn stake --staker-address ${delAddrs[i]} --staking-amount 1000000 --finality-providers-pks $bbn_btc_pk --finality-providers-pks $consumer_btc_pk --staking-time $stakingTime | jq -r '.tx_hash'")
    echo "Delegation was successful; staking tx hash is $btcTxHash"
    i=$((i + 1))
done
echo "Made a delegation to each of the finality providers"

# Query babylon and check if the delegations are active
echo ""
echo "Wait a few minutes for the delegations to become active..."
while true; do
    # Get the active delegations count from Babylon
    activeDelegations=$(docker exec babylondnode0 /bin/sh -c 'babylond q btcstaking btc-delegations active -o json | jq ".btc_delegations | length"')

    echo "Active delegations count in Babylon: $activeDelegations"

    if [ "$activeDelegations" -eq "$NUM_COMSUMER_FPS" ]; then
        echo "All delegations have become active"
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
    delegationsCount=$(docker exec ibcsim-bcd /bin/sh -c "bcd q wasm contract-state smart $btcStakingContractAddr '{\"delegations\":{}}' -o json | jq '.data.delegations | length'")

    echo "Delegations count in contract store: $delegationsCount"

    if [ "$delegationsCount" -eq "$NUM_COMSUMER_FPS" ]; then
        echo "The number of delegations in contract matches the expected count."
        break
    else
        sleep 10
    fi
done

echo ""
echo "Ensuring all finality providers have voting power"...
while true; do
    fp_by_info=$(docker exec ibcsim-bcd /bin/sh -c "bcd query wasm contract-state smart $btcStakingContractAddr '{\"finality_providers_by_power\":{}}' -o json")

    if [ $(echo "$fp_by_info" | jq '.data.fps | length') -ne "$NUM_COMSUMER_FPS" ]; then
        echo "There are less than $NUM_COMSUMER_FPS finality providers"
        sleep 10
    elif jq -e '.data.fps[].power | select(. <= 0)' <<<"$fp_by_info" >/dev/null; then
        echo "Some finality providers have zero voting power"
        sleep 10
    else
        echo "All finality providers have positive voting power"
        break
    fi
done

echo ""
echo "Ensuring all finality providers have submitted finality signatures..."
last_block_height=$(docker exec ibcsim-bcd /bin/sh -c "bcd query blocks --query \"block.height > 1\" --page 1 --limit 1 --order_by desc -o json | jq -r '.blocks[0].header.height'")
last_block_height=$((last_block_height + 1))
while true; do
    cnt=0
    for consumer_btc_pk in $CONSUMER_BTC_PKS; do
        finality_sig_info=$(docker exec ibcsim-bcd /bin/sh -c "bcd query wasm contract-state smart $btcStakingContractAddr '{\"finality_signature\":{\"btc_pk_hex\":\"$consumer_btc_pk\",\"height\":$last_block_height}}' -o json")
        if [ $(echo "$finality_sig_info" | jq '.data | length') -ne "1" ]; then
            echo "The finality provider $consumer_btc_pk hasn't submitted finality signature to $last_block_height yet"
            sleep 10
        else
            echo "The finality provider $consumer_btc_pk has submitted finality signature to $last_block_height"
            cnt=$((cnt + 1))
        fi
    done
    if [ "$cnt" -eq $NUM_COMSUMER_FPS ]; then
        echo "All of $consumer_btc_pk finality providers have submitted finality signatures!"
        break
    fi
done

echo ""
echo "Ensuring the block on the consumer chain is finalised by BTC staking..."
while true; do
    indexed_block=$(docker exec ibcsim-bcd /bin/sh -c "bcd query wasm contract-state smart $btcStakingContractAddr '{\"block\":{\"height\":$last_block_height}}' -o json")
    if [ $(echo "$indexed_block" | jq '.data.finalized') != "true" ]; then
        echo "The block at height $last_block_height is not finalised yet"
        sleep 10
    else
        echo "The block at height $last_block_height is finalised!"
        break
    fi
done
