#!/bin/bash
set -euo pipefail

sleep 7
echo "fund vigilante account on Babylon"

VIGILANTE_ADDR=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond keys add vigilante \
    --home $BABYLON_HOME_DIR/.tmpdir \
    --keyring-backend test \
    --output json" | jq -r .address)
echo "VIGILANTE_ADDR: $VIGILANTE_ADDR"
echo
sleep 2

FUND_VIGILANTE_TX_HASH=$(docker exec babylondnode0 /bin/sh -c "
    /bin/babylond tx bank send \
    $TEST_SPENDING_KEY_NAME \
    $VIGILANTE_ADDR \
    100000000ubbn \
    --home $BABYLON_HOME_DIR \
    --chain-id $BABYLON_CHAIN_ID \
    --keyring-backend test \
    --gas-prices 0.2ubbn \
    --gas auto \
    --gas-adjustment 1.3 \
    -o json -y" | jq -r '.txhash')
echo "FUND_VIGILANTE_TX_HASH: $FUND_VIGILANTE_TX_HASH"
echo
sleep 5

echo "1====="
mkdir -p .testnets/vigilante/keyring-test .testnets/vigilante/bbnconfig
echo "2====="
mv .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/vigilante/keyring-test
echo "3====="
cp .testnets/node0/babylond/config/genesis.json .testnets/vigilante/bbnconfig
echo "4====="
[[ "$(uname)" == "Linux" ]] && chown -R 1138:1138 .testnets/vigilante
echo "5====="