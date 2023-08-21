#!/bin/bash

echo "Creating keyrings and send funds to Babylon Node Consumers"

sleep 15
docker exec babylondnode0 /bin/sh -c '
    BTC_STAKER_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        btc-staker --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${BTC_STAKER_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mkdir -p .testnets/btc-staker/keyring-test
mv .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/btc-staker/keyring-test
[[ "$(uname)" == "Linux" ]] && chown -R 1138:1138 .testnets/btc-staker

sleep 10
docker exec babylondnode0 /bin/sh -c '
    BTC_VALIDATOR_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        btc-validator --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${BTC_VALIDATOR_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mkdir -p .testnets/btc-validator/keyring-test
mv .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/btc-validator/keyring-test
[[ "$(uname)" == "Linux" ]] && chown -R 1138:1138 .testnets/btc-validator

sleep 10
docker exec babylondnode0 /bin/sh -c '
    VIGILANTE_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        vigilante --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${VIGILANTE_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mkdir -p .testnets/vigilante/keyring-test
mv .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/vigilante/keyring-test
[[ "$(uname)" == "Linux" ]] && chown -R 1138:1138 .testnets/vigilante

sleep 10
docker exec babylondnode0 /bin/sh -c '
    BTC_JURY_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        btc-jury --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${BTC_JURY_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mkdir -p .testnets/btc-jury/keyring-test
mv .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/btc-jury/keyring-test
[[ "$(uname)" == "Linux" ]] && chown -R 1138:1138 .testnets/btc-jury

echo "Created keyrings and sent funds"

NUM_VALIDATORS=3
echo "Create $NUM_VALIDATORS Bitcoin validators"

for idx in `seq 1 $NUM_VALIDATORS`; do
    docker exec btc-validator /bin/sh -c "
        /bin/valcli dn cv --key-name validator$idx && \
        /bin/valcli dn rv --key-name validator$idx
    "
done

echo "Created $NUM_VALIDATORS Bitcoin validators"

echo "Make a delegation to each of the validators from a dedicated BTC address"
sleep 10

# Get the public keys of the validators
btcPks=$(docker exec btc-staker /bin/sh -c '/bin/stakercli dn bv | jq -r ".validators[].bitcoin_public_Key"')
babylonPks=$(docker exec btc-staker /bin/sh -c '/bin/stakercli dn bv | jq -r ".validators[].babylon_public_Key"')

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
        "/bin/stakercli dn stake --staker-address ${delAddrs[i]} --staking-amount 1000000 --validator-pk $btcPk --staking-time $stakingTime | jq -r '.tx_hash'")
    i=$((i+1))
done

echo "Made a delegation to each of the validators"

echo "Wait a few minutes for the delegations to become active..."
while true; do
    allDelegationsActive=$(docker exec btc-validator /bin/sh -c \
        'valcli dn ls | jq ".validators[].last_voted_height != null"')

    if [[ $allDelegationsActive == *"false"* ]]
    then
        sleep 10
    else
        echo "All delegations have become active"
        break
    fi
done

echo "Attack Babylon by submitting a conflicting finality signature for a validator"
# Select the first Validator
attackerBabylonPk=$(echo ${babylonPks}  | cut -d " " -f 1)
attackHeight=$(docker exec btc-validator /bin/sh -c '/bin/valcli dn ls | jq -r ".validators[].last_voted_height" | head -n 1')

# Execute the attack for the first height that every validator voted
docker exec btc-validator /bin/sh -c \
    "/bin/valcli dn afs --babylon-pk $attackerBabylonPk --height $attackHeight"

echo "Validator with Bitcoin public key $attackerBabylonPk submitted a conflicting finality signature for Babylon height $attackHeight; the Validator's private BTC key has been extracted and the Validator will now be slashed"

echo "Wait a few minutes for the last, shortert BTC delegation (10 BTC blocks) to expire..."
sleep 90

echo "Unbond the expired staked BTC funds"
docker exec btc-staker /bin/sh -c \
    "/bin/stakercli dn ust --staking-transaction-hash $btcTxHash"
