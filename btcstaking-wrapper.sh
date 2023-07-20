#!/bin/bash

echo "Creating keyrings and send funds to Babylon Node Consumers (stored on babylondnode0)"

sleep 15
docker exec babylondnode0 /bin/sh -c '
    BTC_STAKER_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        btc-staker --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${BTC_STAKER_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mv .testnets/node0/babylond/.tmpdir/keyring-test .testnets/btc-staker/
sleep 10
docker exec babylondnode0 /bin/sh -c ' 
    BTC_VALIDATOR_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        btc-validator --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${BTC_VALIDATOR_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mv .testnets/node0/babylond/.tmpdir/keyring-test .testnets/btc-validator/
sleep 10
docker exec babylondnode0 /bin/sh -c ' 
    VIGILANTE_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        vigilante --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${VIGILANTE_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mv .testnets/node0/babylond/.tmpdir/keyring-test .testnets/vigilante/

echo "Created keyrings and sent funds"

# TODO: user story 1: create BTC validator and BTC delegation

# TODO: user story 2: jury signature to BTC delegation

# TODO: user story 3: commit public randomness and vote blocks

# TODO: user story 4: equivocation and slashing
