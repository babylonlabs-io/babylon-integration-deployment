#!/bin/bash

echo "Creating keyrings and send funds to Babylon Node Consumers (stored on babylondnode0)"

sleep 15
docker exec babylondnode0 /bin/sh -c ' 
    VIGILANTE_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        vigilante --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${VIGILANTE_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mv .testnets/node0/babylond/.tmpdir/keyring-test .testnets/vigilante/
