#!/bin/bash

echo "Creating keyrings and send funds to Babylon Node Consumers (stored on babylondnode0)"

sleep 15
docker exec babylondnode0 /bin/sh -c '
    BTC_STAKER_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        btc-staker --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${BTC_STAKER_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mkdir -p .testnets/btc-staker/keyring-test
cp -R .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/btc-staker/keyring-test
rm -rf .testnets/node0/babylond/.tmpdir/keyring-test/*

sleep 10
docker exec babylondnode0 /bin/sh -c ' 
    BTC_VALIDATOR_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        btc-validator --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${BTC_VALIDATOR_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mkdir -p .testnets/btc-validator/keyring-test
cp -R .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/btc-validator/keyring-test
rm -rf .testnets/node0/babylond/.tmpdir/keyring-test/*

sleep 10
docker exec babylondnode0 /bin/sh -c ' 
    BTC_JURY_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        btc-jury --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${BTC_JURY_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mkdir -p .testnets/btc-jury/keyring-test
cp -R .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/btc-jury/keyring-test
rm -rf .testnets/node0/babylond/.tmpdir/keyring-test/*

sleep 10
docker exec babylondnode0 /bin/sh -c ' 
    VIGILANTE_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        vigilante --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${VIGILANTE_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mkdir -p .testnets/vigilante/keyring-test
cp -R .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/vigilante/keyring-test

echo "Created keyrings and sent funds"

# TODO: user story 1: create BTC validator and BTC delegation

NUM_VALIDATORS=3
echo "Create $NUM_VALIDATORS Bitcoin validators"

for idx in `seq 1 $NUM_VALIDATORS`; do
    docker exec btc-validator /bin/sh -c "
        /bin/valcli dn cv --key-name validator$idx && \
        /bin/valcli dn rv --key-name validator$idx
    "
done

echo "Make a delegation to each of the validators"
sleep 30
# Get the public keys of the validators
btcPks=$(docker exec btc-staker /bin/sh -c '/bin/stakercli dn bv' | jq ".validators[].btcPublicKey" | tr -d '"')

# Get the Bitcoin address of the delegator
delAddr=$(docker exec btc-staker /bin/sh -c '/bin/stakercli dn list-outputs | jq ".outputs[].address"' | head -1 | tr -d '"')

for btcPk in $btcPks
do
    echo "Delegating from $delAddr to $btcPk";
    docker exec btc-staker /bin/sh -c \
        "/bin/stakercli dn stake --staker-address $delAddr --staking-amount 1000000 --validator-pk $btcPk --staking-time 500"
done


# TODO: user story 2: jury signature to BTC delegation

# TODO: user story 3: commit public randomness and vote blocks

# TODO: user story 4: equivocation and slashing
