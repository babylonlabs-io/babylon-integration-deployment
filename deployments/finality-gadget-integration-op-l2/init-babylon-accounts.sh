#!/bin/bash
set -euo pipefail

echo "=== Fund vigilante account on Babylon"

function init_babylon_account() {
    local account_name=$1
    echo "account_name: $account_name"
    echo "BABYLON_HOME_DIR: $BABYLON_HOME_DIR"

    local account_addr=$(docker exec babylondnode0 /bin/sh -c "
        /bin/babylond keys add $account_name \
        --home $BABYLON_HOME_DIR/.tmpdir \
        --keyring-backend test \
        --output json" | jq -r .address)
    echo "account_addr: $account_addr"
    sleep 2

    local fund_tx_hash=$(docker exec babylondnode0 /bin/sh -c "
        /bin/babylond tx bank send \
        $TEST_SPENDING_KEY_NAME \
        $account_addr \
        100000000ubbn \
        --home $BABYLON_HOME_DIR \
        --chain-id $BABYLON_CHAIN_ID \
        --keyring-backend test \
        --gas-prices 0.2ubbn \
        --gas auto \
        --gas-adjustment 1.3 \
        -o json -y" | jq -r '.txhash')
    echo "fund_tx_hash: $fund_tx_hash"
}

init_babylon_account vigilante
sleep 7
init_babylon_account btc-staker
sleep 7
init_babylon_account finality-provider
sleep 7

# after creating and funding the vigilante account, move the keyring to the testnet dir
mkdir -p .testnets/vigilante/keyring-test .testnets/vigilante/bbnconfig
mv .testnets/node0/babylond/.tmpdir/keyring-test/* .testnets/vigilante/keyring-test
cp .testnets/node0/babylond/config/genesis.json .testnets/vigilante/bbnconfig
if [[ "$(uname)" == "Linux" ]]; then
    chown -R 1138:1138 .testnets/vigilante
    echo "chown done for .testnets/vigilante on $(uname) system"
elif [[ "$(uname)" == "Darwin" ]]; then # for MacOS
    docker run --rm -v "$(pwd)/.testnets/vigilante:/data" alpine chown -R 1138:1138 /data
    echo "chown done for .testnets/vigilante on $(uname) system"
else
    echo "unsupported $(uname) system"
    exit 1
fi
echo
