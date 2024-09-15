#!/bin/bash
set -euo pipefail

echo "=== Fund accounts on Babylon"

function init_babylon_account() {
    local account_name=$1
    echo "account_name: $account_name"

    if [ "$account_name" == "covenant-emulator" ]; then
        local account_addr=$(docker exec babylondnode0 /bin/sh -c "
            /bin/babylond keys show covenant \
            --home $BABYLON_HOME_DIR/$account_name \
            --keyring-backend test \
            --output json" | jq -r .address)
    else
        local account_addr=$(docker exec babylondnode0 /bin/sh -c "
            /bin/babylond keys add $account_name \
            --home $BABYLON_HOME_DIR/$account_name \
            --keyring-backend test \
            --output json" | jq -r .address)
    fi
    echo "account_addr: $account_addr"
    sleep 5

    if [ "$account_name" == "consumer-finality-provider" ]; then
        local fund_tx_hash=$(docker exec babylondnode0 /bin/sh -c "
            /bin/babylond tx bank send \
            $TEST_SPENDING_KEY_NAME \
            $account_addr \
            60000000000ubbn \
            --home $BABYLON_HOME_DIR \
            --chain-id $BABYLON_CHAIN_ID \
            --keyring-backend test \
            --gas-prices 0.2ubbn \
            --gas auto \
            --gas-adjustment 1.3 \
            -o json -y" | jq -r '.txhash')
    else
        local fund_tx_hash=$(docker exec babylondnode0 /bin/sh -c "
            /bin/babylond tx bank send \
            $TEST_SPENDING_KEY_NAME \
            $account_addr \
            1000000000ubbn \
            --home $BABYLON_HOME_DIR \
            --chain-id $BABYLON_CHAIN_ID \
            --keyring-backend test \
            --gas-prices 0.2ubbn \
            --gas auto \
            --gas-adjustment 1.3 \
            -o json -y" | jq -r '.txhash')
    fi
    echo "fund_tx_hash: $fund_tx_hash"
}

init_babylon_account vigilante
echo
sleep 7
init_babylon_account btc-staker
echo
sleep 7
init_babylon_account finality-provider
echo
sleep 7
init_babylon_account consumer-finality-provider
echo
sleep 7
init_babylon_account covenant-emulator
echo
sleep 7

function setup_account_keyring() {
    local account_name=$1
    mkdir -p .testnets/$account_name/keyring-test
    cp .testnets/node0/babylond/$account_name/keyring-test/* .testnets/$account_name/keyring-test
}

function chown_testnet_dir() {
    local account_name=$1
    if [[ "$(uname)" == "Linux" ]]; then
        chown -R 1138:1138 .testnets/$account_name
        echo "chown done for .testnets/$account_name on $(uname) system"
    elif [[ "$(uname)" == "Darwin" ]]; then # for MacOS
        docker run --rm -v "$(pwd)/.testnets/$account_name:/data" alpine chown -R 1138:1138 /data
        echo "chown done for .testnets/$account_name on $(uname) system"
    else
        echo "unsupported $(uname) system"
        exit 1
    fi
}

mkdir -p .testnets/vigilante/bbnconfig
cp .testnets/node0/babylond/config/genesis.json .testnets/vigilante/bbnconfig
setup_account_keyring vigilante
chown_testnet_dir vigilante
echo

setup_account_keyring btc-staker
chown_testnet_dir btc-staker
echo

setup_account_keyring finality-provider
chown_testnet_dir finality-provider
echo

setup_account_keyring consumer-finality-provider
chown_testnet_dir consumer-finality-provider
echo

chown_testnet_dir covenant-emulator
echo