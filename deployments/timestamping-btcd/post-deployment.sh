#!/bin/bash

echo "Creating keyring and sending funds to Vigilante"

sleep 15
docker exec babylondnode0 /bin/sh -c '
    VIGILANTE_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        vigilante --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${VIGILANTE_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mkdir -p .testnets/vigilante/keyring-test
mv .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/vigilante/keyring-test
[[ "$(uname)" == "Linux" ]] && chown -R 1138:1138 .testnets/vigilante

echo "Created keyring and sent funds"
