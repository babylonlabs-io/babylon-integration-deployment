#!/bin/bash

echo "Create $NUM_VALIDATORS Bitcoin validators"

for idx in $(seq 0 $((NUM_VALIDATORS-1))); do
    docker exec btc-validator$idx /bin/sh -c "
        BTC_PK=\$(/bin/valcli cv --key-name validator$idx \
            --chain-id chain-test | jq -r .btc_pk ); \
        /bin/valcli rv --btc-pk \$BTC_PK
    "
done

echo "Created $NUM_VALIDATORS Bitcoin validators"

echo "Make a delegation to each of the validators from a dedicated BTC address"
sleep 10

# Get the public keys of the validators
btcPks=$(docker exec btc-staker /bin/sh -c '/bin/stakercli dn bv | jq -r ".validators[].bitcoin_public_Key"')

# Get the available BTC addresses for delegations
delAddrs=($(docker exec btc-staker /bin/sh -c '/bin/stakercli dn list-outputs | jq -r ".outputs[].address" | sort | uniq'))

i=0
for btcPk in $btcPks
do
    # Let `X=NUM_VALIDATORS`
    # For the first X - 1 requests, we select a staking period of 500 BTC
    # blocks. The Xth request will last only for 10 BTC blocks, so that we can
    # showcase the reclamation of expired BTC funds afterwards.
    if [ $((i % $NUM_VALIDATORS)) -eq $((NUM_VALIDATORS -1)) ];
    then
        stakingTime=10
    else
        stakingTime=500
    fi

    echo "Delegating 1 million Satoshis from BTC address ${delAddrs[i]} to Validator with Bitcoin public key $btcPk for $stakingTime BTC blocks";

    btcTxHash=$(docker exec btc-staker /bin/sh -c \
        "/bin/stakercli dn stake --staker-address ${delAddrs[i]} --staking-amount 1000000 --validator-pks $btcPk --staking-time $stakingTime | jq -r '.tx_hash'")
    i=$((i+1))
done

echo "Made a delegation to each of the validators"

echo "Wait a few minutes for the delegations to become active..."
while true; do
    delegationsActive=$(docker exec btc-validator0 /bin/sh -c \
        'valcli ls | jq ".validators[].last_voted_height != null"')

    if [[ $delegationsActive == *"false"* ]]
    then
        sleep 10
    else
        echo "At least one delegation have become active"
        break
    fi
done

echo "Attack Babylon by submitting a conflicting finality signature for a validator"
# Select the first Validator
attackerBtcPk=$(docker exec btc-validator0 /bin/sh -c '/bin/valcli ls | jq -r ".validators[].btc_pk_hex" | head -n 1')
attackHeight=$(docker exec btc-validator0 /bin/sh -c '/bin/valcli ls | jq -r ".validators[].last_voted_height" | head -n 1')

# Execute the attack for the first height that every validator voted
docker exec btc-validator0 /bin/sh -c \
    "/bin/valcli afs --btc-pk $attackerBtcPk --height $attackHeight"

echo "Validator with Bitcoin public key $attackerBtcPk submitted a conflicting finality signature for Babylon height $attackHeight; the Validator's private BTC key has been extracted and the Validator will now be slashed"

echo "Wait a few minutes for the last, shortest BTC delegation (10 BTC blocks) to expire..."
sleep 180

echo "Withdraw the expired staked BTC funds"
docker exec btc-staker /bin/sh -c \
    "/bin/stakercli dn ust --staking-transaction-hash $btcTxHash"
