#!/bin/bash -eu

# USAGE:
# ./fpd-start

# it starts the finality provider for single node chain and validator
CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../..}"

FPD_BUILD="${FPD_BUILD:-$BBN_DEPLOYMENTS/finality-provider/build}"
FPD_BIN="${FPD_BIN:-$FPD_BUILD/fpd}"
FPDCLI_BIN="${FPDCLI_BIN:-$FPD_BUILD/fpcli}"

BABYLOND_DIR="${BABYLOND_DIR:-$BBN_DEPLOYMENTS/babylon}"
BBN_BIN="${BBN_BIN:-$BABYLOND_DIR/build/babylond}"

CHAIN_ID="${CHAIN_ID:-test-1}"
CHAIN_DIR="${CHAIN_DIR:-$CWD/data}"
FPD_HOME="${FPD_HOME:-$CHAIN_DIR/fpd}"
CLEANUP="${CLEANUP:-1}"

n0dir="$CHAIN_DIR/$CHAIN_ID/n0"
listenAddr="127.0.0.1:12583"

homeF="--home $FPD_HOME"
cid="--chain-id $CHAIN_ID"
dAddr="--daemon-address $listenAddr"
cfg="$FPD_HOME/fpd.conf"
outdir="$FPD_HOME/out"
logdir="$FPD_HOME/logs"
fpKeyName="keys-finality-provider"

# babylon node Home flag for folder
n0dir="$CHAIN_DIR/$CHAIN_ID/n0"
homeN0="--home $n0dir"
kbt="--keyring-backend test"

if [[ "$CLEANUP" == 1 || "$CLEANUP" == "1" ]]; then
  PATH_OF_PIDS=$FPD_HOME/*.pid $CWD/kill-process.sh

  rm -rf $FPD_HOME
  echo "Removed $FPD_HOME"
fi

if [ ! -f $FPD_BIN ]; then
  echo "$FPD_BIN does not exists. build it first with $~ make"
  exit 1
fi

if [ ! -f $FPDCLI_BIN ]; then
  echo "$FPDCLI_BIN does not exists. build it first with $~ make"
  exit 1
fi

mkdir -p $outdir
mkdir -p $logdir

# Creates and modifies config
$FPD_BIN init $homeF --force

perl -i -pe 's|DBPath = '$HOME'/.fpd/data|DBPath = "'$FPD_HOME/data'"|g' $cfg
perl -i -pe 's|ChainID = chain-test|ChainID = "'$CHAIN_ID'"|g' $cfg
perl -i -pe 's|BitcoinNetwork = signet|BitcoinNetwork = simnet|g' $cfg
perl -i -pe 's|Port = 2112|Port = 2734|g' $cfg
perl -i -pe 's|RpcListener = 127.0.0.1:12581|RpcListener = "'$listenAddr'"|g' $cfg

# Adds new key for the finality provider
$FPD_BIN keys add --key-name $fpKeyName $cid $homeF > $outdir/keys-add-keys-finality-provider.txt

# Starts the finality provider daemon
pid_file=$FPD_HOME/fpd.pid
$FPD_BIN start --rpc-listener $listenAddr $homeF > $logdir/fpd-start.log 2>&1 &
echo $! > $pid_file
sleep 2

# Creates the finality provider and stores it into the database and eots
createFPFile=$outdir/create-finality-provider.json
$FPDCLI_BIN create-finality-provider --key-name $fpKeyName $cid $homeF $dAddr --moniker val-fp > $createFPFile
btcPKHex=$(cat $createFPFile | jq '.btc_pk_hex' -r)

# Transfer funds to the fp acc created
fpBbnAddr=$($BBN_BIN $homeF keys show $fpKeyName -a $kbt)
$BBN_BIN tx bank send user $fpBbnAddr 100000000ubbn $homeN0 $kbt $cid -y

# Register the finality provider
registerFPFile=$outdir/register-finality-provider.json
$FPDCLI_BIN register-finality-provider $dAddr --btc-pk $btcPKHex > $registerFPFile
