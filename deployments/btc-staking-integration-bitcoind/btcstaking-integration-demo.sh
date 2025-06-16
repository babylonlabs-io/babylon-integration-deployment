#!/bin/bash

set -e  # Exit on any error

BBN_CHAIN_ID="chain-test"

echo "🚀 Starting BTC Staking Integration Demo"
echo "=============================================="

echo ""
echo "⏳ Step 1: Waiting for relayer key recovery..."
while true; do
    # Check if both keys are recovered by querying them
    BABYLON_ADDRESS=$(docker exec ibcsim-bcd /bin/sh -c "rly --home /data/relayer keys list babylon 2>/dev/null" | cut -d' ' -f3)
    BCD_ADDRESS=$(docker exec ibcsim-bcd /bin/sh -c "rly --home /data/relayer keys list bcd 2>/dev/null" | cut -d' ' -f3)

    if [ -n "$BABYLON_ADDRESS" ] && [ -n "$BCD_ADDRESS" ]; then
        echo "  ✅ Successfully recovered keys for both chains"
        break
    else
        echo "  → Waiting for key recovery... (babylon: $BABYLON_ADDRESS, bcd: $BCD_ADDRESS)"
        sleep 5
    fi
done

echo ""
echo "🔗 Step 2: Creating IBC Light Clients and Connection"

echo "  → Creating IBC light clients on Babylon and bcd..."
docker exec ibcsim-bcd /bin/sh -c "rly --home /data/relayer tx clients bcd"
[ $? -eq 0 ] && echo "  ✅ Created IBC light clients successfully!" || echo "  ❌ Error creating IBC light clients"

sleep 10

echo "  → Querying client ID registered in Babylon node..."
CONSUMER_ID=$(docker exec babylondnode0 babylond query ibc client states -o json | jq -r '.client_states[0].client_id')
[ -n "$CONSUMER_ID" ] && echo "  ✅ Found client ID: $CONSUMER_ID" || echo "  ❌ Error: Could not find client ID"

echo "  → Creating IBC connection between Babylon and bcd..."
docker exec ibcsim-bcd /bin/sh -c "rly --home /data/relayer tx connection bcd"
[ $? -eq 0 ] && echo "  ✅ Created IBC connection successfully!" || echo "  ❌ Error creating IBC connection"

echo ""
echo "📡 Step 3: Creating IBC Channel for Transfer"

echo "  → Creating IBC channel for IBC transfer..."
docker exec ibcsim-bcd /bin/sh -c "rly --home /data/relayer tx channel bcd --src-port transfer --dst-port transfer --order unordered --version ics20-1"
[ $? -eq 0 ] && echo "  ✅ Created IBC transfer channel successfully!" || echo "  ❌ Error creating IBC transfer channel"

echo ""
echo "📝 Step 4: Registering Consumer Chain"

echo "  → Registering the consumer with ID: $CONSUMER_ID"
docker exec babylondnode0 /bin/sh -c "/bin/babylond --home /babylondhome tx btcstkconsumer register-consumer $CONSUMER_ID consumer-name consumer-description 2 --from test-spending-key --chain-id $BBN_CHAIN_ID --keyring-backend test --fees 100000ubbn -y"

echo "  → Verifying consumer registration..."
while true; do
    # Consumer should be automatically registered in Babylon via IBC, query registered consumers
    CONSUMER_REGISTERS=$(docker exec babylondnode0 /bin/sh -c "/bin/babylond query btcstkconsumer registered-consumers -o json | jq -r '.consumer_registers'")

    # Check if there's exactly one consumer ID and it matches the expected CONSUMER_ID
    if [ $(echo "$CONSUMER_REGISTERS" | jq '. | length') -eq 1 ] && [ $(echo "$CONSUMER_REGISTERS" | jq -r '.[0].consumer_id') = "$CONSUMER_ID" ]; then
        echo "  ✅ Consumer '$CONSUMER_ID' registered successfully"
        break
    else
        echo "  → Waiting for consumer registration..."
        sleep 10
    fi
done

echo ""
echo "🌐 Step 5: Creating ZoneConcierge IBC Channel"

echo "  → Querying contract address..."
CONTRACT_ADDRESS=$(docker exec ibcsim-bcd /bin/sh -c 'bcd query wasm list-contract-by-code 1 -o json | jq -r ".contracts[0]"')
CONTRACT_PORT="wasm.$CONTRACT_ADDRESS"
echo "  ✅ Contract address: $CONTRACT_ADDRESS"

echo "  → Creating IBC channel for zoneconcierge..."
docker exec ibcsim-bcd /bin/sh -c "rly --home /data/relayer tx channel bcd --src-port zoneconcierge --dst-port $CONTRACT_PORT --order ordered --version zoneconcierge-1"
[ $? -eq 0 ] && echo "  ✅ Created zoneconcierge IBC channel successfully!" || echo "  ❌ Error creating zoneconcierge IBC channel"

sleep 20

echo ""
echo "🚀 Step 6: Starting Relayer"

echo "  → Starting the relayer daemon..."
docker exec ibcsim-bcd /bin/sh -c "nohup rly --home /data/relayer start bcd --debug-addr '' --flush-interval 30s > /data/relayer/relayer.log 2>&1 &"
echo "  ✅ Relayer started! Logs: /data/relayer/relayer.log"

echo ""
echo "⏳ Step 7: Waiting for IBC Channels"
echo "  → Waiting for IBC channels to be ready..."
while true; do
    # Fetch the port ID and channel ID from the Consumer IBC channel list
    channelInfoJson=$(docker exec ibcsim-bcd /bin/sh -c "bcd query ibc channel channels -o json")

    # Check if there are any channels available
    channelsLength=$(echo $channelInfoJson | jq -r '.channels | length')
    if [ "$channelsLength" -gt 1 ]; then
        echo "  ✅ Found $channelsLength channels:"
        echo "$channelInfoJson" | jq -r '.channels[] | "    • Port ID: \(.port_id), Channel ID: \(.channel_id)"'
        # Store second channel info for later use
        portId=$(echo "$channelInfoJson" | jq -r '.channels[1].port_id')
        channelId=$(echo "$channelInfoJson" | jq -r '.channels[1].channel_id')
        break
    else
        echo "  → Found only $channelsLength channels, retrying in 10 seconds..."
        sleep 10
    fi
done

echo ""
echo "🎉 Integration between Babylon and bcd is ready!"
echo "Now we will try out BTC staking on the consumer chain..."

echo "  → Getting contract addresses..."
btcStakingContractAddr=$(docker exec ibcsim-bcd /bin/sh -c 'bcd q wasm list-contract-by-code 3 -o json | jq -r ".contracts[0]"')
btcFinalityContractAddr=$(docker exec ibcsim-bcd /bin/sh -c 'bcd q wasm list-contract-by-code 4 -o json | jq -r ".contracts[0]"')
echo "  ✅ BTC Staking Contract: $btcStakingContractAddr"
echo "  ✅ BTC Finality Contract: $btcFinalityContractAddr"

echo ""
echo "👥 Step 8: Creating Finality Providers"

echo ""
echo "  → Creating Babylon Finality Provider..."
bbn_btc_pk=$(docker exec eotsmanager /bin/sh -c "
    /bin/eotsd keys add finality-provider --keyring-backend=test --rpc-client \"0.0.0.0:15813\" --output=json
")

echo "  → Generating EOTS key..."
# Filter out warning messages and get only the JSON part
bbn_btc_pk=$(echo "$bbn_btc_pk" | grep -v "Warning:" | jq -r '.pubkey_hex')
if [ -z "$bbn_btc_pk" ]; then
    echo "  ❌ Failed to generate Babylon EOTS public key"
    exit 1
fi
echo "  ✅ Babylon EOTS public key: $bbn_btc_pk"

echo "  → Creating finality provider on-chain..."
bbn_fp_output=$(docker exec finality-provider /bin/sh -c "
    /bin/fpd cfp \
        --key-name finality-provider \
        --chain-id $BBN_CHAIN_ID \
        --eots-pk $bbn_btc_pk \
        --commission-rate 0.05 \
        --commission-max-rate 0.20 \
        --commission-max-change-rate 0.01 \
        --moniker \"Babylon finality provider\" 2>&1"
)

# Filter out the text message and parse only the JSON part
bbn_btc_pk=$(echo "$bbn_fp_output" | grep -v "Your finality provider is successfully created" | jq -r '.finality_provider.btc_pk_hex')
if [ -z "$bbn_btc_pk" ]; then
    echo "  ❌ Failed to extract Babylon BTC public key"
    exit 1
fi
echo "  ✅ Created Babylon finality provider"
echo "  ✅ BTC PK: $bbn_btc_pk"

echo "  → Restarting Babylon finality provider..."
docker restart finality-provider
echo "  ✅ Babylon finality provider restarted"

echo ""
echo "  → Creating Consumer Finality Provider..."
consumer_btc_pk=$(docker exec consumer-eotsmanager /bin/sh -c "
    /bin/eotsd keys add finality-provider --keyring-backend=test --rpc-client \"0.0.0.0:15813\" --output=json
")

echo "  → Generating Consumer EOTS key..."
# Filter out warning messages and get only the JSON part
consumer_btc_pk=$(echo "$consumer_btc_pk" | grep -v "Warning:" | jq -r '.pubkey_hex')
if [ -z "$consumer_btc_pk" ]; then
    echo "  ❌ Failed to generate Consumer EOTS public key"
    exit 1
fi
echo "  ✅ Consumer EOTS public key: $consumer_btc_pk"

echo "  → Creating consumer finality provider on-chain..."
consumer_fp_output=$(docker exec consumer-fp /bin/sh -c "
    /bin/fpd cfp \
        --key-name finality-provider \
        --chain-id $CONSUMER_ID \
        --eots-pk $consumer_btc_pk \
        --commission-rate 0.05 \
        --commission-max-rate 0.20 \
        --commission-max-change-rate 0.01 \
        --moniker \"Consumer finality Provider\" 2>&1"
)

# Filter out the text message and parse only the JSON part
consumer_btc_pk=$(echo "$consumer_fp_output" | grep -v "Your finality provider is successfully created" | jq -r '.finality_provider.btc_pk_hex')
if [ -z "$consumer_btc_pk" ]; then
    echo "  ❌ Failed to extract Consumer BTC public key"
    exit 1
fi
echo "  ✅ Created consumer finality provider"
echo "  ✅ BTC PK: $consumer_btc_pk"

echo "  → Restarting Consumer finality provider..."
docker restart consumer-fp
echo "  ✅ Consumer finality provider restarted"

echo ""
echo "✅ Step 9: Verifying Finality Provider Storage"
echo "  → Checking if contract has stored the finality providers..."
while true; do
    # Get the finality providers count from the contract state
    finalityProvidersCount=$(docker exec ibcsim-bcd /bin/sh -c "bcd q wasm contract-state smart $btcStakingContractAddr '{\"finality_providers\":{}}' -o json | jq '.data.fps | length'")

    echo "  → Finality provider count in contract: $finalityProvidersCount"

    if [ "$finalityProvidersCount" -eq "1" ]; then
        echo "  ✅ Contract has stored 1 finality provider"
        break
    else
        echo "  → Finality providers not yet stored in contract, retrying in 10 seconds..."
        sleep 10
    fi
done

echo ""
echo "🎲 Step 10: Ensuring Public Randomness Commitment"
echo "  → Checking public randomness commitment..."
while true; do
    pr_commit_info=$(docker exec ibcsim-bcd /bin/sh -c "bcd query wasm contract-state smart $btcFinalityContractAddr '{\"last_pub_rand_commit\":{\"btc_pk_hex\":\"$consumer_btc_pk\"}}' -o json")
    if [[ "$(echo "$pr_commit_info" | jq '.data')" == *"null"* ]]; then
        echo "  → Waiting for public randomness commitment..."
        sleep 10
    else
        echo "  ✅ Finality provider has committed public randomness"
        break
    fi
done

echo ""
echo "₿ Step 11: Creating BTC Delegation"
echo "  → Getting available BTC addresses..."
sleep 5
# Get the available BTC addresses for delegations
delAddrs=($(docker exec btc-staker /bin/sh -c '/bin/stakercli dn list-outputs | jq -r ".outputs[].address" | sort | uniq'))
stakingTime=10000
stakingAmount=1000000

echo "  ✅ Using BTC address: ${delAddrs[0]}"
echo "  → Delegating $stakingAmount satoshis for $stakingTime blocks..."
echo "    • Babylon FP: $bbn_btc_pk"
echo "    • Consumer FP: $consumer_btc_pk"

btcTxHash=$(docker exec btc-staker /bin/sh -c \
    "/bin/stakercli dn stake --staker-address ${delAddrs[0]} --staking-amount $stakingAmount --finality-providers-pks $bbn_btc_pk --finality-providers-pks $consumer_btc_pk --staking-time $stakingTime | jq -r '.tx_hash'")

if [ -n "$btcTxHash" ] && [ "$btcTxHash" != "null" ]; then
    echo "  ✅ BTC delegation successful!"
    echo "  ✅ Transaction hash: $btcTxHash"
else
    echo "  ❌ Failed to create BTC delegation"
    exit 1
fi

echo ""
echo "⏳ Step 12: Waiting for Delegation Activation"
echo "  → Monitoring delegation status in Babylon..."
while true; do
    # Get the active delegations count from Babylon
    activeDelegations=$(docker exec babylondnode0 /bin/sh -c 'babylond q btcstaking btc-delegations active -o json | jq ".btc_delegations | length"')

    echo "  → Active delegations count: $activeDelegations"

    if [ "$activeDelegations" -eq 1 ]; then
        echo "  ✅ Delegation is now active in Babylon!"
        break
    else
        echo "  → Waiting for delegation to activate..."
        sleep 10
    fi
done

echo ""
echo "📝 Step 13: Verifying Contract Storage"
echo "  → Checking if contract has stored the delegations..."
while true; do
    # Get the delegations count from the contract state
    delegationsCount=$(docker exec ibcsim-bcd /bin/sh -c "bcd q wasm contract-state smart $btcStakingContractAddr '{\"delegations\":{}}' -o json | jq '.data.delegations | length'")

    echo "  → Delegations count in contract: $delegationsCount"

    if [ "$delegationsCount" -eq 1 ]; then
        echo "  ✅ Contract has stored the delegation"
        break
    else
        echo "  → Delegations not yet stored in contract, retrying in 10 seconds..."
        sleep 10
    fi
done

echo ""
echo "⚡ Step 14: Verifying Voting Power"
echo "  → Ensuring finality providers have voting power..."
while true; do
    fp_by_info=$(docker exec ibcsim-bcd /bin/sh -c "bcd query wasm contract-state smart $btcStakingContractAddr '{\"finality_providers_by_power\":{}}' -o json")

    if [ $(echo "$fp_by_info" | jq '.data.fps | length') -ne 1 ]; then
        echo "  → Waiting for finality providers to gain voting power..."
        sleep 10
    elif jq -e '.data.fps[].power | select(. <= 0)' <<<"$fp_by_info" >/dev/null; then
        echo "  → Some finality providers have zero voting power, waiting..."
        sleep 10
    else
        echo "  ✅ All finality providers have positive voting power"
        break
    fi
done

echo ""
echo "✍️ Step 15: Verifying Finality Signatures"
last_block_height=$(docker exec ibcsim-bcd /bin/sh -c "bcd query blocks --query \"block.height > 1\" --page 1 --limit 1 --order_by desc -o json | jq -r '.blocks[0].header.height'")
last_block_height=$((last_block_height + 1))
echo "  → Checking finality signatures for block $last_block_height..."
while true; do
    finality_sig_info=$(docker exec ibcsim-bcd /bin/sh -c "bcd query wasm contract-state smart $btcFinalityContractAddr '{\"finality_signature\":{\"btc_pk_hex\":\"$consumer_btc_pk\",\"height\":$last_block_height}}' -o json")
    if [ $(echo "$finality_sig_info" | jq '.data | length') -ne "1" ]; then
        echo "  → Waiting for finality signature submission..."
        sleep 10
    else
        echo "  ✅ Finality signature submitted for block $last_block_height"
        break
    fi
done

echo ""
echo "🎯 Step 16: Verifying Block Finalization"
echo "  → Checking if block $last_block_height is finalized..."
while true; do
    indexed_block=$(docker exec ibcsim-bcd /bin/sh -c "bcd query wasm contract-state smart $btcFinalityContractAddr '{\"block\":{\"height\":$last_block_height}}' -o json")
    finalized=$(echo "$indexed_block" | jq -r '.data.finalized')
    if [ -z "$finalized" ]; then
        echo "  → Unable to determine finalization status, retrying..."
        sleep 10
    elif [ "$finalized" != "true" ]; then
        echo "  → Block $last_block_height is not finalized yet, waiting..."
        sleep 10
    else
        echo "  ✅ Block $last_block_height is finalized by BTC staking!"
        break
    fi
done

echo ""
echo "🎉 BTC Staking Integration Demo Complete!"
echo "=========================================="
echo ""
echo "✅ Consumer registered: $CONSUMER_ID"
echo "✅ BTC Staking Contract: $btcStakingContractAddr"
echo "✅ BTC Finality Contract: $btcFinalityContractAddr"
echo "✅ Babylon FP BTC PK: $bbn_btc_pk"
echo "✅ Consumer FP BTC PK: $consumer_btc_pk"
echo "✅ BTC Delegation TX: $btcTxHash"
echo "✅ Block $last_block_height: FINALIZED"
echo ""
echo "🚀 The integration is now fully operational!"
echo "   Consumer chain blocks are being finalized via BTC staking."
