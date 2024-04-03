#!/bin/bash -eu

# USAGE:
# ./vigilante-start

# Starts an vigilate submitter and reporter connected to babylon and btc chain.

CWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

CHAIN_ID="${CHAIN_ID:-test-1}"
CHAIN_DIR="${CHAIN_DIR:-$CWD/data}"
CHAIN_HOME="$CHAIN_DIR/$CHAIN_ID"

BBN_DEPLOYMENTS="${BBN_DEPLOYMENTS:-$CWD/../..}"

BABYLOND_DIR="${BABYLOND_DIR:-$BBN_DEPLOYMENTS/babylon}"
BBN_BIN="${BBN_BIN:-$BABYLOND_DIR/build/babylond}"

VIGILANTE_BIN="${VIGILANTE_BIN:-$BBN_DEPLOYMENTS/vigilante/build/vigilante}"

N0_HOME="${N0_HOME:-$CHAIN_HOME/n0}"
BTC_HOME="${BTC_HOME:-$CHAIN_DIR/btc}"
VIGILANTE_HOME="${VIGILANTE_HOME:-$CHAIN_DIR/vigilante}"
CLEANUP="${CLEANUP:-1}"

echo "--- Chain Dir = $CHAIN_DIR"
echo "--- BTC HOME = $BTC_HOME"

vigilantepidPath="$VIGILANTE_HOME/pid"
vigilanteLogs="$VIGILANTE_HOME/logs"

if [[ "$CLEANUP" == 1 || "$CLEANUP" == "1" ]]; then
  PATH_OF_PIDS=$vigilantepidPath/*.pid $CWD/kill-process.sh

  rm -rf $VIGILANTE_HOME
  echo "Removed $VIGILANTE_HOME"
fi

if [ ! -f $VIGILANTE_BIN ]; then
  echo "$VIGILANTE_BIN does not exists. build it first with $~ make"
  exit 1
fi

mkdir -p $VIGILANTE_HOME
mkdir -p $vigilantepidPath
mkdir -p $vigilanteLogs

btcCertPath=$BTC_HOME/certs
btcRpcCert=$btcCertPath/rpc.cert
btcWalletRpcCert=$btcCertPath/rpc-wallet.cert

vigilanteConfSub=$VIGILANTE_HOME/vigilante-submitter.yml
vigilanteConfRep=$VIGILANTE_HOME/vigilante-reporter.yml

reporterpid="$vigilantepidPath/reporter.pid"
submitterpid="$vigilantepidPath/submitter.pid"

kbt="--keyring-backend test"
submitterAddr=$($BBN_BIN --home $N0_HOME keys show submitter -a $kbt)

# Creates one config for each vigilante process
CONF_PATH=$vigilanteConfSub CLEANUP=0 SUBMITTER_ADDR=$submitterAddr $CWD/vigilante-setup-conf.sh
CONF_PATH=$vigilanteConfRep CLEANUP=0 SUBMITTER_ADDR=$submitterAddr SERVER_PORT=2134 LISTEN_PORT=8068 $CWD/vigilante-setup-conf.sh

# Starts reporter and submitter
$VIGILANTE_BIN --config $vigilanteConfRep reporter > $vigilanteLogs/reporter.log 2>&1 &
echo $! > $reporterpid

$VIGILANTE_BIN --config $vigilanteConfSub submitter > $vigilanteLogs/submitter.log 2>&1 &
echo $! > $submitterpid