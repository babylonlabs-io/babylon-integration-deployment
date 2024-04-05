#!/bin/bash

BBN_CHAIN_ID="chain-test"
CZ_CHAIN_ID="test-consumer-chain"
CZ_CHAIN_NAME="test-consumer-chain"
CZ_CHAIN_DESC="test-consumer-chain-description"

sleep 10

# register a consumer chain
echo "Registering a consumer chain"

docker exec babylondnode0 /bin/sh -c "/bin/babylond --home /babylondhome tx btcstkconsumer register-chain $CZ_CHAIN_ID $CZ_CHAIN_NAME $CZ_CHAIN_DESC --from test-spending-key --fees 2ubbn -y --chain-id $BBN_CHAIN_ID --keyring-backend test"

echo "Registered a consumer chain with chain ID $CZ_CHAIN_ID"

# create FPs for Babylon
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
            --chain-id $CZ_CHAIN_ID \
            --moniker \"Finality Provider $idx\" | jq -r .btc_pk_hex ); \
        /bin/fpcli rfp --btc-pk \$BTC_PK
    "
done

echo "Created $NUM_CZ_FPs consumer chain finality providers"

# Get the public keys of the consumer chain finality providers
cz_btc_pks=$(docker exec babylondnode0 /bin/sh -c "/bin/babylond query btcstkconsumer finality-providers $CZ_CHAIN_ID --output json" | jq -r ".finality_providers[].btc_pk")
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

echo ""
echo "Wait a few minutes for the delegations to become active..."
while true; do
    allDelegationsActive=$(docker exec finality-provider /bin/sh -c 'fpcli ls | jq ".finality_providers[].last_voted_height != null"')

    if [[ $allDelegationsActive == *"false"* ]]
    then
        sleep 10
    else
        echo "All delegations have become active"
        break
    fi
done
