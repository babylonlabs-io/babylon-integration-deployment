#!/bin/bash -eu

# USAGE:
# ./covd-start

# it starts the covenant for single node chain

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../..}"

COVD_BIN="${COVD_BIN:-$BBN_DEPLOYMENTS/covenant-emulator/build/covd}"

BABYLOND_DIR="${BABYLOND_DIR:-$BBN_DEPLOYMENTS/babylon}"
BBN_BIN="${BBN_BIN:-$BABYLOND_DIR/build/babylond}"

CHAIN_ID="${CHAIN_ID:-test-1}"
CHAIN_DIR="${CHAIN_DIR:-$CWD/data}"
COVD_HOME="${COVD_HOME:-$CHAIN_DIR/covd}"
CLEANUP="${CLEANUP:-1}"
SETUP="${SETUP:-1}"

if [ ! -f $COVD_BIN ]; then
  echo "$COVD_BIN does not exists. build it first with $~ make"
  exit 1
fi

if [ ! -f $BBN_BIN ]; then
  echo "$BBN_BIN does not exists. build it first with $~ make"
  exit 1
fi

homeF="--home $COVD_HOME"
n0dir="$CHAIN_DIR/$CHAIN_ID/n0"
homeN0="--home $n0dir"
kbt="--keyring-backend test"
cid="--chain-id $CHAIN_ID"

if [[ "$CLEANUP" == 1 || "$CLEANUP" == "1" ]]; then
  PATH_OF_PIDS=$COVD_HOME/*.pid $CWD/kill-process.sh

  rm -rf $COVD_HOME
  echo "Removed $COVD_HOME"
fi

if [[ "$SETUP" == 1 || "$SETUP" == "1" ]]; then
  $CWD/covd-setup.sh
fi

# transfer funds to the covenant acc created
covenantAddr=$($BBN_BIN $homeF keys show covenant -a $kbt)
$BBN_BIN tx bank send user $covenantAddr 100000000ubbn $homeN0 $kbt $cid -y

# Start Covenant
$COVD_BIN start $homeF >> $COVD_HOME/covd-start.log &
echo $! > $COVD_HOME/covd.pid
