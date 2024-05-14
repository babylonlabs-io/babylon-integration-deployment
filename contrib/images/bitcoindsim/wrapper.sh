#!/usr/bin/env bash
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

txindex=1
deprecatedrpc=create_bdb

# Fallback fee
fallbackfee=0.00001

# Allow all IPs to access the RPC server.
[regtest]
rpcbind=0.0.0.0
rpcallowip=0.0.0.0/0
" > "$BITCOIN_CONF"

GENERATE_STAKER_WALLET="${GENERATE_STAKER_WALLET:=true}"
echo "Starting bitcoind..."
bitcoind  -regtest -datadir="$BITCOIN_DATA" -conf="$BITCOIN_CONF" -daemon
# Allow some time for bitcoind to start
sleep 3
echo "Creating a wallet..."
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" createwallet "$WALLET_NAME" false false "$WALLET_PASS" false false
echo "Generating 110 blocks for the first coinbases to mature..."
bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" -generate 110

if [[ "$GENERATE_STAKER_WALLET" == "true" ]]; then
  echo "Creating a wallet and $BTCSTAKER_WALLET_ADDR_COUNT addresses for btcstaker..."
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" createwallet "$BTCSTAKER_WALLET_NAME" false false "$WALLET_PASS" false false

  BTCSTAKER_ADDRS=()
  for i in `seq 0 1 $((BTCSTAKER_WALLET_ADDR_COUNT - 1))`
  do
    BTCSTAKER_ADDRS+=($(bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$BTCSTAKER_WALLET_NAME" getnewaddress))
  done

  # Generate a UTXO for each btc-staker address
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" walletpassphrase "$WALLET_PASS" 1
  for addr in "${BTCSTAKER_ADDRS[@]}"
  do
    bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" sendtoaddress "$addr" 10
  done

  # Allow some time for the wallet to catch up.
  sleep 5

  echo "Checking balance..."
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" getbalance
fi

echo "Generating a block every ${GENERATE_INTERVAL_SECS} seconds."
echo "Press [CTRL+C] to stop..."
while true
do
  bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" -generate 1
  if [[ "$GENERATE_STAKER_WALLET" == "true" ]]; then
    echo "Periodically send funds to btcstaker addresses..."
    bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" walletpassphrase "$WALLET_PASS" 1
    for addr in "${BTCSTAKER_ADDRS[@]}"
    do
      bitcoin-cli -regtest -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcwallet="$WALLET_NAME" sendtoaddress "$addr" 10
    done
  fi
  sleep "${GENERATE_INTERVAL_SECS}"
done