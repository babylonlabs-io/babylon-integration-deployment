#!/usr/bin/env sh

# 0. Define configuration
BABYLON_KEY="babylon-key"
BABYLON_CHAIN_ID="chain-test"
WASMD_KEY="wasmd-key"
WASMD_CHAIN_ID="wasmd-test"

# 1. Create a wasmd testnet with Babylon contract
./setup-wasmd.sh $WASMD_CHAIN_ID $WASMD_CONF 26657 26656 6060 9090 ./babylon_contract.wasm '{"btc_confirmation_depth":1,"checkpoint_finalization_timeout":2,"network":"Regtest","babylon_tag":[1,2,3,4]}'

sleep 10

CONTRACT_ADDRESS=$(wasmd query wasm list-contract-by-code 1 | grep wasm | cut -d' ' -f2)
CONTRACT_PORT="wasm.$CONTRACT_ADDRESS"
echo "wasmd started. Status of Wasmd node:"
wasmd status
echo "Contract port: $CONTRACT_PORT"

# 2. Set up the relayer
mkdir -p $RELAYER_CONF_DIR
rly --home $RELAYER_CONF_DIR config init
RELAYER_CONF=$RELAYER_CONF_DIR/config/config.yaml

cat <<EOT >$RELAYER_CONF
global:
    api-listen-addr: :5183
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
    wasmd:
        type: cosmos
        value:
            key: $WASMD_KEY
            chain-id: $WASMD_CHAIN_ID
            rpc-addr: http://localhost:26657
            account-prefix: wasm
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
    wasmd:
        src:
            chain-id: $BABYLON_CHAIN_ID
            port-id: zoneconcierge
            channel-id: channel-0
            order: ordered
            version: zoneconcierge-1
        dst:
            chain-id: $WASMD_CHAIN_ID
            port-id: $CONTRACT_PORT
            channel-id: channel-0
            order: ordered
            version: zoneconcierge-1
EOT

echo "Inserting the wasmd key"
WASMD_MEMO=$(cat $WASMD_CONF/$WASMD_CHAIN_ID/key_seed.json | jq .mnemonic | tr -d '"')
rly --home $RELAYER_CONF_DIR keys restore wasmd $WASMD_KEY "$WASMD_MEMO"

echo "Inserting the babylond key"
BABYLON_MEMO=$(cat $BABYLON_HOME/key_seed.json | jq .secret | tr -d '"')
rly --home $RELAYER_CONF_DIR keys restore babylon $BABYLON_KEY "$BABYLON_MEMO"

sleep 10

# 3. Start relayer

echo "Create light clients in both CZs"
rly --home $RELAYER_CONF_DIR tx clients wasmd
sleep 10

echo "Create IBC Connection between the two CZs"
rly --home $RELAYER_CONF_DIR tx connection wasmd

echo "Create an IBC channel between the two CZs"
rly --home $RELAYER_CONF_DIR tx channel wasmd --src-port zoneconcierge --dst-port $CONTRACT_PORT --order ordered --version zoneconcierge-1
sleep 10

echo "Start the IBC relayer"
rly --home $RELAYER_CONF_DIR start wasmd --debug-addr ""
