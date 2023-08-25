#!/bin/bash

echo "Creating keyrings and sending funds to Babylon Node Consumers"

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
