#!/bin/sh

# Create new directory that will hold node and services' configuration
mkdir -p .testnets && chmod o+w .testnets
docker run --rm -v $(pwd)/.testnets:/data babylonchain/babylond \
    babylond testnet init-files --v 2 -o /data \
    --starting-ip-address 192.168.10.2 --keyring-backend=test \
    --chain-id chain-test --epoch-interval 10 \
    --btc-finalization-timeout 2 --btc-confirmation-depth 1 \
    --minimum-gas-prices 0.000006ubbn \
    --btc-network regtest --additional-sender-account \
    --slashing-address "mfcGAzvis9JQAb6avB6WBGiGrgWzLxuGaC" \
    --jury-pk "945feee5f9e5dd1dfc43717987ffef60b9d8ee4301d0deebae6be0637964dcbe"

# Create separate subpaths for each component and copy relevant configuration
mkdir -p .testnets/bitcoin
mkdir -p .testnets/vigilante
cp artifacts/vigilante.yml .testnets/vigilante/vigilante.yml
