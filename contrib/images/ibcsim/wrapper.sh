#!/usr/bin/env sh
set -euo pipefail
#set -x


GAIA_CHAIN_CONF=$IBC_CHAINS_CONF/gaia.json
BABYLON_CHAIN_CONF=$IBC_CHAINS_CONF/babylon.json
PATH_NAME="gaia-babylon"
PATH_CONF=$IBC_PATHS_CONF/$PATH_NAME.json

mkdir -p $IBC_CHAINS_CONF
mkdir -p $IBC_PATHS_CONF


# 0. Define configuration
BABYLON_KEY="babylon-key"
BABYLON_CHAIN_ID="chain-test"
GAIA_KEY="gaia-key"
GAIA_CHAIN_ID="gaia-test"
cat <<EOT > $BABYLON_CHAIN_CONF
{
  "type": "cosmos",
  "value": {
    "key": "$BABYLON_KEY",
    "chain-id": "$BABYLON_CHAIN_ID",
    "rpc-addr": "$BABYLON_NODE_RPC",
    "grpc-addr": "",
    "account-prefix": "bbn",
    "keyring-backend": "test",
    "gas-adjustment": 1.5,
    "gas-prices": "0.002ubbn",
    "debug": true,
    "timeout": "10s",
    "output-format": "json",
    "sign-mode": "direct"
  }
}
EOT

cat <<EOT > $GAIA_CHAIN_CONF
{
  "type": "cosmos",
  "value": {
    "key": "$GAIA_KEY",
    "chain-id": "$GAIA_CHAIN_ID",
    "rpc-addr": "http://localhost:26657",
    "grpc-addr": "",
    "account-prefix": "cosmos",
    "keyring-backend": "test",
    "gas-adjustment": 1.5,
    "gas-prices": "0.025stake",
    "debug": true,
    "timeout": "10s",
    "output-format": "json",
    "sign-mode": "direct"
  }
}
EOT

cat <<EOT > $PATH_CONF
{
  "src": {
    "chain-id": "$BABYLON_CHAIN_ID",
    "port-id": "zoneconcierge",
    "channel-id": "channel-0",
    "order": "unordered",
    "version": "zoneconcierge-1"
  },
  "dst": {
    "chain-id": "$GAIA_CHAIN_ID",
    "port-id": "zoneconcierge",
    "channel-id": "channel-0",
    "order": "unordered",
    "version": "ics20-1"
  },
  "strategy": {
    "type": "naive"
  },
  "src-channel-filter": {
    "rule": null,
    "channel-list": []
  }
}
EOT


# 1. Create a gaiad testnet

# Create testnet dirs for one validator
echo "Creating testnet dirs..."
gaiad testnet \
    --v                     1 \
    --output-dir            $GAIA_CONF \
    --starting-ip-address   192.168.10.2 \
    --keyring-backend       test \
    --minimum-gas-prices    "0.00002stake" \
    --chain-id              $GAIA_CHAIN_ID

echo "$(sed 's/cors_allowed_origins = \[\]/cors_allowed_origins = \[\"*\"\]/g' $GAIA_CONF/node0/gaiad/config/config.toml)" > $GAIA_CONF/node0/gaiad/config/config.toml
# Start the gaiad service
echo "Starting the gaiad service..."
echo "hi"
GAIA_LOG=$GAIA_CONF/node0/gaiad/gaiad.log
gaiad --home $GAIA_CONF/node0/gaiad start \
      --pruning=nothing --grpc-web.enable=false \
      --rpc.unsafe true \
      --grpc.address="0.0.0.0:9091" > $GAIA_LOG 2>&1 &

echo "gaiad started. Logs outputted at $GAIA_LOG"
sleep 10
echo "Status of Gaia node"
gaiad status

# 2. Create the relayer
echo "Initializing relayer"
rly --home $RELAYER_CONF config init
echo "Adding chains configuration"
rly --home $RELAYER_CONF chains add-dir $IBC_CHAINS_CONF

echo "Inserting the gaiad key"
GAIA_MEMO=$(cat $GAIA_CONF/node0/gaiad/key_seed.json | jq .secret | tr -d '"')
rly --home $RELAYER_CONF keys restore gaia $GAIA_KEY "$GAIA_MEMO"

echo "Inserting the babylond key"
BABYLON_MEMO=$(cat $BABYLON_HOME/key_seed.json | jq .secret | tr -d '"')
rly --home $RELAYER_CONF keys restore babylon $BABYLON_KEY "$BABYLON_MEMO"

echo "Inserting config paths"
rly --home $RELAYER_CONF paths add-dir $IBC_PATHS_CONF

sleep 30

echo "Create light clients in both CZs"
rly --home $RELAYER_CONF tx clients $PATH_NAME

sleep 30
echo "Create IBC Connection between the two CZs"
rly --home $RELAYER_CONF tx connection $PATH_NAME

echo "Create an IBC channel between the two CZs"
rly --home $RELAYER_CONF tx channel $PATH_NAME --src-port zoneconcierge --dst-port transfer --order unordered --version ics20-1

# 3. Relay headers
while true
do
    echo "Relaying headers between Babylon and Gaia..."
    rly --home $RELAYER_CONF tx update-clients $PATH_NAME
    sleep $UPDATE_CLIENTS_INTERVAL_SEC
done
