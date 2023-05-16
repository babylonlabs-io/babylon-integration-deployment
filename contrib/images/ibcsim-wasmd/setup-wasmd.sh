#!/bin/bash

display_usage() {
	echo "Missing parameters. Please check if all parameters were specified."
	echo "Usage: setup-wasmd.sh [CHAIN_ID] [CHAIN_DIR] [RPC_PORT] [P2P_PORT] [PROFILING_PORT] [GRPC_PORT] [CODE_DIR] [INSTANTIATING_CFG]"
	echo "Example: setup-wasmd.sh test-chain-id ./data 26657 26656 6060 9090 ./babylon_contract.wasm '{"btc_confirmation_depth":1,"checkpoint_finalization_timeout":2,"network":"Regtest","babylon_tag":"bbn0"}'"
	exit 1
}

BINARY=wasmd
DENOM=stake
BASEDENOM=ustake
KEYRING=--keyring-backend="test"
SILENT=1

redirect() {
	if [ "$SILENT" -eq 1 ]; then
		"$@" >/dev/null 2>&1
	else
		"$@"
	fi
}

if [ "$#" -lt "8" ]; then
	display_usage
	exit 1
fi

CHAINID=$1
CHAINDIR=$2
RPCPORT=$3
P2PPORT=$4
PROFPORT=$5
GRPCPORT=$6
CODE_DIR=$7
INSTANTIATING_CFG=$8

# ensure the binary exists
if ! command -v $BINARY &>/dev/null; then
	echo "$BINARY could not be found"
	exit
fi

# Delete chain data from old runs
echo "Deleting $CHAINDIR/$CHAINID folders..."
rm -rf $CHAINDIR/$CHAINID &>/dev/null
rm $CHAINDIR/$CHAINID.log &>/dev/null

echo "Creating $BINARY instance: home=$CHAINDIR | chain-id=$CHAINID | p2p=:$P2PPORT | rpc=:$RPCPORT | profiling=:$PROFPORT | grpc=:$GRPCPORT"

# Add dir for chain, exit if error
if ! mkdir -p $CHAINDIR/$CHAINID 2>/dev/null; then
	echo "Failed to create chain folder. Aborting..."
	exit 1
fi
# Build genesis file incl account for passed address
coins="100000000000$DENOM,100000000000$BASEDENOM"
delegate="100000000000$DENOM"

redirect $BINARY --home $CHAINDIR/$CHAINID --chain-id $CHAINID init $CHAINID
sleep 1
$BINARY --home $CHAINDIR/$CHAINID keys add validator $KEYRING --output json >$CHAINDIR/$CHAINID/validator_seed.json 2>&1
sleep 1
$BINARY --home $CHAINDIR/$CHAINID keys add user $KEYRING --output json >$CHAINDIR/$CHAINID/key_seed.json 2>&1
sleep 1
redirect $BINARY --home $CHAINDIR/$CHAINID add-genesis-account $($BINARY --home $CHAINDIR/$CHAINID keys $KEYRING show user -a) $coins
sleep 1
redirect $BINARY --home $CHAINDIR/$CHAINID add-genesis-account $($BINARY --home $CHAINDIR/$CHAINID keys $KEYRING show validator -a) $coins
sleep 1
redirect $BINARY --home $CHAINDIR/$CHAINID gentx validator $delegate $KEYRING --chain-id $CHAINID
sleep 1
redirect $BINARY --home $CHAINDIR/$CHAINID collect-gentxs
sleep 1

# Set proper defaults and change ports
echo "Change settings in config.toml and genesis.json files..."
sed -i 's#"tcp://127.0.0.1:26657"#"tcp://0.0.0.0:'"$RPCPORT"'"#g' $CHAINDIR/$CHAINID/config/config.toml
sed -i 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:'"$P2PPORT"'"#g' $CHAINDIR/$CHAINID/config/config.toml
sed -i 's#"localhost:6060"#"localhost:'"$P2PPORT"'"#g' $CHAINDIR/$CHAINID/config/config.toml
sed -i 's/timeout_commit = "5s"/timeout_commit = "1s"/g' $CHAINDIR/$CHAINID/config/config.toml
sed -i 's/max_body_bytes = 1000000/max_body_bytes = 1000000000/g' $CHAINDIR/$CHAINID/config/config.toml
sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "0.00001ustake"/g' $CHAINDIR/$CHAINID/config/app.toml
sed -i 's/timeout_propose = "3s"/timeout_propose = "1s"/g' $CHAINDIR/$CHAINID/config/config.toml
sed -i 's/index_all_keys = false/index_all_keys = true/g' $CHAINDIR/$CHAINID/config/config.toml
sed -i 's#"tcp://0.0.0.0:1317"#"tcp://0.0.0.0:1318"#g' $CHAINDIR/$CHAINID/config/app.toml # ensure port is not conflicted with Babylon
sed -i 's/"bond_denom": "stake"/"bond_denom": "'"$DENOM"'"/g' $CHAINDIR/$CHAINID/config/genesis.json
# sed -i '' 's#index-events = \[\]#index-events = \["message.action","send_packet.packet_src_channel","send_packet.packet_sequence"\]#g' $CHAINDIR/$CHAINID/config/app.toml

# Start
echo "Starting $BINARY..."
$BINARY --home $CHAINDIR/$CHAINID start --pruning=nothing --grpc-web.enable=false --grpc.address="0.0.0.0:$GRPCPORT" >$CHAINDIR/$CHAINID.log 2>&1 &
sleep 20

# upload contract code
echo "Uploading contract code $CODE_DIR..."
$BINARY --home $CHAINDIR/$CHAINID tx wasm store $CODE_DIR --keyring-backend="test" --from user --chain-id $CHAINID --gas 20000000000 --gas-prices 0.01ustake --node http://localhost:$RPCPORT -y
sleep 5

# instantiate contract
# node that the code id is guaranteed to be 1
echo "Instantiating contract with code $CODE_DIR..."
$BINARY --home $CHAINDIR/$CHAINID tx wasm instantiate 1 $INSTANTIATING_CFG --admin=$(wasmd --home $CHAINDIR/$CHAINID keys show user --keyring-backend test -a) --label "v0.0.1" --keyring-backend="test" --from user --chain-id $CHAINID --gas 20000000000 --gas-prices 0.001ustake --node http://localhost:$RPCPORT -y --amount 100000stake
