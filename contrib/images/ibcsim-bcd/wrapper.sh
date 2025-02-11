#!/usr/bin/env sh
# shellcheck disable=SC3037

# 0. Define configuration
BABYLON_KEY="babylon-key"
BABYLON_CHAIN_ID="chain-test"
CONSUMER_KEY="bcd-key"
CONSUMER_CHAIN_ID="bcd-test"

# 1. Create a bcd testnet with Babylon contract
./setup-bcd.sh $CONSUMER_CHAIN_ID $CONSUMER_CONF 26657 26656 6060 9090 ./babylon_contract.wasm ./btc_staking.wasm ./btc_finality.wasm

sleep 5

# TODO: query babylon module for getting the contract address
CONTRACT_ADDRESS=$(bcd query wasm list-contract-by-code 1 | grep bbnc | cut -d' ' -f2)
CONTRACT_PORT="wasm.$CONTRACT_ADDRESS"
echo "bcd started. Status of bcd node:"
bcd status
echo "Contract port: $CONTRACT_PORT"

# 2. Set up the relayer
mkdir -p $RELAYER_CONF_DIR
rly --home $RELAYER_CONF_DIR config init
RELAYER_CONF=$RELAYER_CONF_DIR/config/config.yaml

cat <<EOT >$RELAYER_CONF
global:
    api-listen-addr: :5183
    max-retries: 20
    timeout: 20s
    memo: ""
    light-cache-size: 10
chains:
    babylon:
        type: cosmos
        value:
            key: $BABYLON_KEY
            chain-id: $BABYLON_CHAIN_ID
            rpc-addr: $BABYLON_NODE_RPC
            account-prefix: bbn
            keyring-backend: test
            gas-adjustment: 1.5
            gas-prices: 0.002ubbn
            min-gas-amount: 1
            debug: true
            timeout: 10s
            output-format: json
            sign-mode: direct
            extra-codecs: []
    bcd:
        type: cosmos
        value:
            key: $CONSUMER_KEY
            chain-id: $CONSUMER_CHAIN_ID
            rpc-addr: http://localhost:26657
            account-prefix: bbnc
            keyring-backend: test
            gas-adjustment: 1.5
            gas-prices: 0.002ustake
            min-gas-amount: 1
            debug: true
            timeout: 10s
            output-format: json
            sign-mode: direct
            extra-codecs: []     
paths:
    bcd:
        src:
            chain-id: $BABYLON_CHAIN_ID
        dst:
            chain-id: $CONSUMER_CHAIN_ID
EOT

echo "Inserting the consumer key"
CONSUMER_MEMO=$(cat $CONSUMER_CONF/$CONSUMER_CHAIN_ID/key_seed.json | jq .mnemonic | tr -d '"')
rly --home $RELAYER_CONF_DIR keys restore bcd $CONSUMER_KEY "$CONSUMER_MEMO"

echo "Inserting the babylond key"
BABYLON_MEMO=$(cat $BABYLON_HOME/key_seed.json | jq .secret | tr -d '"')
rly --home $RELAYER_CONF_DIR keys restore babylon $BABYLON_KEY "$BABYLON_MEMO"

sleep 10

# 3. Create IBC light clients
echo "Creating IBC light clients on Babylon and bcd"
rly --home $RELAYER_CONF_DIR tx clients bcd
[ $? -eq 0 ] && echo "Created IBC light clients successfully!" || echo "Error creating IBC light clients"

sleep 10

# 4. Create IBC channels
echo "Creating IBC channel for zoneconcierge"
rly --home $RELAYER_CONF_DIR tx link bcd --src-port zoneconcierge --dst-port $CONTRACT_PORT --order ordered --version zoneconcierge-1
[ $? -eq 0 ] && echo "Created zonecincierge IBC channel successfully!" || echo "Error creating zonecincierge IBC channel"

echo "Creating IBC channel for IBC transfer"
rly --home $RELAYER_CONF_DIR tx link bcd --src-port transfer --dst-port transfer --order unordered --version ics20-1 &
[ $? -eq 0 ] && echo "Created IBC transfer channel successfully!" || echo "Error creating IBC transfer channel"

sleep 10

# 5. Start the IBC relayer
echo "Start the IBC relayer"
rly --home $RELAYER_CONF_DIR start bcd --debug-addr "" --flush-interval 30s
