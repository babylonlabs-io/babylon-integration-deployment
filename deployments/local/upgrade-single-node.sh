#!/bin/bash -eu

# USAGE:
# ./single-node-upgrade.sh $NODE_BIN_V1 $NODE_BIN_V2 softwareUpgradeName

# Does an upgrade from v1 to v2 from sending a gov prop update, voting and
# waiting to the gov prop to be ready kill the previous pid from node and
# starts from the new one that has the new version.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NODE_BIN_V1="${1:-$CWD/../../babylon/build/babylond}"
NODE_BIN_V2="${2:-$CWD/upgrades/babylond-v2-vanilla-2425b66919f085c1cc3e843bb0e31470a97fe3ee}"
SOFTWARE_UPGRADE_FILE="${3:-$CWD/upgrades/vanilla.json}"

CHAIN_ID="${CHAIN_ID:-test-1}"
CHAIN_DIR="${CHAIN_DIR:-$CWD/data}"
DENOM="${DENOM:-ubbn}"

if [ ! -f $NODE_BIN_V1 ]; then
  echo "$NODE_BIN_V1 does not exists. build it first with $~ make"
  exit 1
fi

if [ ! -f $NODE_BIN_V2 ]; then
  echo "$NODE_BIN_V2 does not exists. build it first with $~ make"
  exit 1
fi

hdir="$CHAIN_DIR/$CHAIN_ID"

# Folder for node
n0dir="$hdir/n0"

# Home flag for folder
home0="--home $n0dir"

# Process id of node 0
n0pid="$hdir/n0.pid"
log_path=$hdir/n0.v2.log

# Common flags
kbt="--keyring-backend test"
cid="--chain-id $CHAIN_ID"

VAL0_ADDR=$($NODE_BIN_V1 $home0 keys show val -a $kbt --bech val)

UPGRADE_BLOCK_HEIGHT=`$NODE_BIN_V1 status | jq ".sync_info.latest_block_height | tonumber | . + 12"`
echo "upgrade block height: $UPGRADE_BLOCK_HEIGHT"

echo "Send gov proposal to upgrade to '$SOFTWARE_UPGRADE_FILE'"

# Sets the height and proposer to msg
echo $(cat $SOFTWARE_UPGRADE_FILE | jq ".messages[0].plan.height = $UPGRADE_BLOCK_HEIGHT" $SOFTWARE_UPGRADE_FILE) > $SOFTWARE_UPGRADE_FILE
echo $(cat $SOFTWARE_UPGRADE_FILE | jq ".proposer = \"$VAL0_ADDR\"" $SOFTWARE_UPGRADE_FILE) > $SOFTWARE_UPGRADE_FILE

govPropOut=$($NODE_BIN_V1 tx gov submit-proposal $SOFTWARE_UPGRADE_FILE $home0 --from val $kbt $cid --yes --output json --fees 1000ubbn)

# Debug
# echo $govPropOut
# txHash=$(echo $govPropOut | jq -r '.txhash')
# echo "txHash" $txHash

sleep 6 # waits for a block

propID=$($NODE_BIN_V1 q gov proposals -o json | jq -r '.proposals[-1].id')
echo "Prop ID: $propID"

$NODE_BIN_V1 tx gov vote $propID --from val $kbt yes $home0 $cid --yes

echo "..."
echo "Finish voting in the proposal"
echo "It will wait to reach the block height to upgrade"
echo "..."

BLOCK_HEIGHT=0
while [ $BLOCK_HEIGHT -lt $UPGRADE_BLOCK_HEIGHT ]
do
  BLOCK_HEIGHT=`$NODE_BIN_V1 status | jq ".sync_info.latest_block_height | tonumber"`
  echo "Current block height $BLOCK_HEIGHT, waiting to reach $UPGRADE_BLOCK_HEIGHT"
  sleep 3
done

echo "Reached upgrade block height"
echo "Kill all the process '$NODE_BIN_V1'"

PATH_OF_PIDS=$n0pid $CWD/kill-process.sh
sleep 5

$NODE_BIN_V2 $home0 start --api.enable true --grpc.address="0.0.0.0:9090" --api.enabled-unsafe-cors --grpc-web.enable=true --log_level info > $log_path 2>&1 &

# Gets the node pid
echo $! > $n0pid

# Start the instance
echo "--- Starting node..."
echo
echo "Logs:"
echo "  * tail -f $log_path"
echo
echo "Env for easy access:"
echo "export H1='--home $n0dir'"
echo
echo "Command Line Access:"
echo "  * $NODE_BIN_V2 --home $n0dir status"
