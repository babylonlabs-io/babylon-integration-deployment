#!/usr/bin/env sh
set -e

# Create bitcoin data directory and initialize bitcoin configuration file.
mkdir -p "$BITCOIN_DATA"
echo "# Enable regtest mode.
regtest=1

# Accept command line and JSON-RPC commands
server=1

# RPC user and password.
rpcuser=$RPC_USER
rpcpassword=$RPC_PASS

# ZMQ notification options.
zmqpubsequence=tcp://0.0.0.0:$ZMQ_PORT

# Allow all IPs to access the RPC server.
[regtest]
rpcbind=0.0.0.0
rpcallowip=0.0.0.0/0
" > "$BITCOIN_CONF"

echo "Starting bitcoind..."
bitcoind  -regtest -datadir="$BITCOIN_DATA" -conf="$BITCOIN_CONF" -daemon

# Allow some time for bitcoind to start
sleep 3

echo "Creating a wallet..."
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" createwallet "$WALLET_NAME" false false "$WALLET_PASS"

echo "Generating 101 blocks for the first coinbase to mature..."
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -generate 101

# Allow some time for the wallet to catch up.
sleep 5

echo "Checking balance..."
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" getbalance

echo "Generating a block every ${GENERATE_INTERVAL_SECS} seconds."
echo "Press [CTRL+C] to stop..."
while true
do
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -generate 1
  sleep "${GENERATE_INTERVAL_SECS}"
done
