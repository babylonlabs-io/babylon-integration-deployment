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
# Enable publish hash block and tx sequence
zmqpubsequence=tcp://*:$ZMQ_SEQUENCE_PORT
# Enable publishing of raw block hex.
zmqpubrawblock=tcp://*:$ZMQ_RAWBLOCK_PORT
# Enable publishing of raw transaction.
zmqpubrawtx=tcp://*:$ZMQ_RAWTR_PORT


# Fallback fee
fallbackfee=0.00001

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

echo "Creating a wallet and address for btcstaker..."
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" createwallet "$BTCSTAKER_WALLET_NAME" false false "$WALLET_PASS"
BTCSTAKER_ADDR=$(bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTCSTAKER_WALLET_NAME" getnewaddress)

echo "Generating 110 blocks for the first coinbases to mature..."
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" -generate 110
# Generate some UTXOs for the btc-staker
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" walletpassphrase "$WALLET_PASS" 1
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" sendtoaddress "$BTCSTAKER_ADDR" 10
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" sendtoaddress "$BTCSTAKER_ADDR" 10
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" sendtoaddress "$BTCSTAKER_ADDR" 10

# Allow some time for the wallet to catch up.
sleep 5

echo "Checking balance..."
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" getbalance

echo "Generating a block every ${GENERATE_INTERVAL_SECS} seconds."
echo "Press [CTRL+C] to stop..."
while true
do
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" -generate 1
  echo "Periodically send funds to btcstaker address..."
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" walletpassphrase "$WALLET_PASS" 1
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" sendtoaddress "$BTCSTAKER_ADDR" 10
  sleep "${GENERATE_INTERVAL_SECS}"
done
