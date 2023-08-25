#!/bin/sh

echo "Creating keyring and sending funds to the Faucet"

sleep 15
docker exec babylondnode0 /bin/sh -c '
    FAUCET_ADDR=$(/bin/babylond --home /babylondhome/.tmpdir keys add \
        faucet --output json --keyring-backend test | jq -r .address) && \
    /bin/babylond --home /babylondhome tx bank send test-spending-key \
        ${FAUCET_ADDR} 100000000ubbn --fees 2ubbn -y --keyring-backend test
'
mkdir -p .testnets/faucet/keyring-test
mv .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/faucet/keyring-test

echo "Created keyring and sent funds"
