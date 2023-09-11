#!/bin/sh

# Create new directory that will hold node and services' configuration
mkdir -p .testnets && chmod o+w .testnets
docker run --rm -v $(pwd)/.testnets:/data babylonchain/babylond \
    babylond testnet init-files --v 2 -o /data \
    --starting-ip-address 192.168.10.2 --keyring-backend=test \
    --chain-id chain-test --epoch-interval 10 \
    --btc-finalization-timeout 2 --btc-confirmation-depth 1 \
    --minimum-gas-prices 0.000006ubbn \
    --btc-base-header 0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4adae5494dffff7f2002000000 \
    --btc-network regtest --additional-sender-account \
    --slashing-address "mfcGAzvis9JQAb6avB6WBGiGrgWzLxuGaC" \
    --jury-pk "945feee5f9e5dd1dfc43717987ffef60b9d8ee4301d0deebae6be0637964dcbe" # should be updated if `jury-keyring` dir is changed`

# Create separate subpaths for each component and copy relevant configuration
mkdir -p .testnets/bitcoin
mkdir -p .testnets/vigilante
mkdir -p .testnets/btc-staker
mkdir -p .testnets/btc-validator
mkdir -p .testnets/btc-jury
cp artifacts/vigilante.yml .testnets/vigilante/vigilante.yml
cp artifacts/stakerd.conf .testnets/btc-staker/stakerd.conf
cp artifacts/vald.conf .testnets/btc-validator/vald.conf
cp artifacts/juryd.conf .testnets/btc-jury/vald.conf
cp -R artifacts/jury-keyring .testnets/btc-jury/keyring-test
