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
        keys_list=$(docker exec babylondnode0 /bin/sh -c "
            /bin/babylond keys list \
            --home $BABYLON_HOME_DIR/$account_name \
            --keyring-backend test \
            --output json")

        # Check if the key already exists in the keyring
        key_exists=$(echo "$keys_list" | jq -r --arg account_name "$account_name" '.[] | select(.name == $account_name)')

        # If the key does not exist, add it
        if [ -z "$key_exists" ]; then
            echo "Key not found, adding new key..."
            local account_addr=$(docker exec babylondnode0 /bin/sh -c "
                /bin/babylond keys add $account_name \
                --home $BABYLON_HOME_DIR/$account_name \
                --keyring-backend test \
                --output json" | jq -r .address)
            echo "New key added with address: $account_addr"
        else
            # Extract the existing address from the already fetched keys list
            local account_addr=$(echo "$keys_list" | jq -r --arg account_name "$account_name" '.[] | select(.name == $account_name) | .address')
            echo "Key already exists with address: $account_addr"
        fi
    fi
    echo "account_addr: $account_addr"
    sleep 5

    if [ "$account_name" == "consumer-finality-provider" ]; then
        local account_balance=$(docker exec babylondnode0 /bin/sh -c "
            /bin/babylond query bank balances $account_addr \
            --home $BABYLON_HOME_DIR \
            --chain-id $BABYLON_CHAIN_ID \
            --output json" | jq -r .balances[0].amount)
        echo "account_balance: $account_balance"
        # If account not yet funded, fund it
        if [ "$account_balance" = "null" ] || [ -z "$account_balance" ]; then
            echo "account not yet funded, funding it"
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
            echo "fund_tx_hash: $fund_tx_hash"
        else
            echo "account already funded, skipping"
        fi
    else
        local account_balance=$(docker exec babylondnode0 /bin/sh -c "
            /bin/babylond query bank balances $account_addr \
            --home $BABYLON_HOME_DIR \
            --chain-id $BABYLON_CHAIN_ID \
            --output json" | jq -r .balances[0].amount)
        echo "account_balance: $account_balance"
        # If account not yet funded, fund it
        if [ "$account_balance" = "null" ] || [ -z "$account_balance" ]; then
            echo "account not yet funded, funding it"
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
            echo "fund_tx_hash: $fund_tx_hash"
        else
            echo "account already funded, skipping"
        fi
    fi
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

function clear_fp_keyring() {
  docker exec finality-provider /bin/sh -c "
    /bin/fpd keys delete finality-provider \
    --home /home/finality-provider/.fpd \
    --keyring-backend test \
    -y"
}

function setup_account_keyring() {
    local account_name=$1
    if [ ! -d ".testnets/$account_name/keyring-test" ]; then
        mkdir -p .testnets/$account_name/keyring-test
        sudo find .testnets/node0/babylond/$account_name/keyring-test/ -type f -exec cp {} .testnets/$account_name/keyring-test/ \;
    fi
}

function chown_testnet_dir() {
    local account_name=$1
    if [[ "$(uname)" == "Linux" ]]; then
        sudo chown -R 1138:1138 .testnets/$account_name
        echo "chown done for .testnets/$account_name on $(uname) system"
    elif [[ "$(uname)" == "Darwin" ]]; then # for MacOS
        docker run --rm -v "$(pwd)/.testnets/$account_name:/data" alpine chown -R 1138:1138 /data
        echo "chown done for .testnets/$account_name on $(uname) system"
    else
        echo "unsupported $(uname) system"
        exit 1
    fi
}

setup_account_keyring vigilante
chown_testnet_dir vigilante
echo

setup_account_keyring btc-staker
chown_testnet_dir btc-staker
echo

clear_fp_keyring
setup_account_keyring finality-provider
chown_testnet_dir finality-provider
echo

setup_account_keyring consumer-finality-provider
chown_testnet_dir consumer-finality-provider
echo

chown_testnet_dir covenant-emulator
echo