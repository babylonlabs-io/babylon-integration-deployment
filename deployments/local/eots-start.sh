#!/bin/bash -eu

# USAGE:
# ./eots-start

# it starts the eots for finality provider

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../..}"
FPD_BUILD="${FPD_BUILD:-$BBN_DEPLOYMENTS/finality-provider/build}"
EOTS_BIN="${EOTS_BIN:-$FPD_BUILD/eotsd}"

CHAIN_ID="${CHAIN_ID:-test-1}"
CHAIN_DIR="${CHAIN_DIR:-$CWD/data}"
EOTS_HOME="${EOTS_HOME:-$CHAIN_DIR/eots}"
CLEANUP="${CLEANUP:-1}"

if [ ! -f $EOTS_BIN ]; then
  echo "$EOTS_BIN does not exists. build it first with $~ make"
  exit 1
fi

# Home flag for folder
homeF="--home $EOTS_HOME"
cfg="$EOTS_HOME/eotsd.conf"

if [[ "$CLEANUP" == 1 || "$CLEANUP" == "1" ]]; then
  PATH_OF_PIDS=$EOTS_HOME/*.pid $CWD/kill-process.sh

  rm -rf $EOTS_HOME
  echo "Removed $EOTS_HOME"
fi

$EOTS_BIN init $homeF
perl -i -pe 's|DBPath = '$HOME'/.eotsd/data|DBPath = "'$EOTS_HOME/data'"|g' $cfg

# Start Covenant
$EOTS_BIN start $homeF >> $EOTS_HOME/eots-start.log &
echo $! > $EOTS_HOME/eots.pid
