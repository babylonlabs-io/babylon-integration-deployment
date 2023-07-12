#!/usr/bin/env sh
set -euo pipefail
#set -x

# btcctl will be looking for this file, but the wallet doesn't create it.
mkdir -p /root/.btcwallet && touch /root/.btcwallet/btcwallet.conf
mkdir -p /root/.btcwallet_staker && touch /root/.btcwallet_staker/btcwallet.conf
mkdir -p /root/.btcd      && touch /root/.btcd/btcd.conf

# Create a wallet with and a miner address, then mine enough blocks for the miner to have some initial balance.

BITCOIN_CONF=${BITCOIN_CONF:-/bitcoinconf}
MINING_ADDR_FILE="${BITCOIN_CONF}/mining.addr"
BTCSTAKER_ADDR_FILE="${BITCOIN_CONF}/btcstaker.addr"
MINING_WALLET_HOME="/root/.btcwallet"
BTCSTAKER_WALLET_HOME="/root/.btcwallet_staker"
CERT_FILE="${BITCOIN_CONF}/rpc.cert"
KEY_FILE="${BITCOIN_CONF}/rpc.key"
WALLET_CERT_FILE="${BITCOIN_CONF}/rpc-wallet.cert"
WALLET_KEY_FILE="${BITCOIN_CONF}/rpc-wallet.key"

echo "Creating certificates..."
gencerts -d $BITCOIN_CONF -H $CLIENT_HOST -f
mv $CERT_FILE $WALLET_CERT_FILE
mv $KEY_FILE $WALLET_KEY_FILE
gencerts -d $BITCOIN_CONF -H $CLIENT_HOST -f

echo "Starting btcd..."
btcd --simnet -u $RPC_USER -P $RPC_PASS --rpclisten=0.0.0.0:18556 --listen=0.0.0.0:18555 \
      --rpccert $CERT_FILE --rpckey $KEY_FILE 2>&1 &
BTCD_PID=$!

echo "Creating a wallet..."
# Used autoexpect to create the wallet in the first instance.
# https://stackoverflow.com/questions/4857702/how-to-provide-password-to-a-command-that-prompts-for-one-in-bash
expect btcwallet_create.exp $RPC_USER $RPC_PASS $WALLET_PASS $WALLET_CERT_FILE $WALLET_KEY_FILE $CERT_FILE $MINING_WALLET_HOME

echo "Creating a wallet for btcstaker..."
expect btcwallet_create.exp $RPC_USER $RPC_PASS $WALLET_PASS $WALLET_CERT_FILE $WALLET_KEY_FILE $CERT_FILE $BTCSTAKER_WALLET_HOME

echo "Starting btcwallet server under 18554 with btcstaker wallet..."
btcwallet --simnet -u $RPC_USER -P $RPC_PASS --rpclisten=0.0.0.0:18554 \
          --rpccert $WALLET_CERT_FILE --rpckey $WALLET_KEY_FILE \
          --appdata $BTCSTAKER_WALLET_HOME --cafile $CERT_FILE 2>&1 &
BTCWALLET_PID=$!

# Allow some time for the wallet to start
sleep 5

echo "Creating btcstaker address..."
BTCSTAKER_ADDR=$(btcctl --simnet --wallet -u $RPC_USER -P $RPC_PASS --rpccert $WALLET_CERT_FILE getnewaddress)
echo $BTCSTAKER_ADDR > $BTCSTAKER_ADDR_FILE

echo "Restarting btcwallet server under 18554 with mining wallet..."
kill -9 $BTCWALLET_PID
btcwallet --simnet -u $RPC_USER -P $RPC_PASS --rpclisten=0.0.0.0:18554 \
          --rpccert $WALLET_CERT_FILE --rpckey $WALLET_KEY_FILE \
          --appdata $MINING_WALLET_HOME --cafile $CERT_FILE 2>&1 &
BTCWALLET_PID=$!
echo "Starting btcwallet server under 18564 with btcstaker wallet..."
btcwallet --simnet -u $RPC_USER -P $RPC_PASS --rpclisten=0.0.0.0:18564 \
          --rpccert $WALLET_CERT_FILE --rpckey $WALLET_KEY_FILE \
          --appdata $BTCSTAKER_WALLET_HOME --cafile $CERT_FILE 2>&1 &
BTCWALLET_STAKER_PID=$!

# Allow some time for the wallets to start
sleep 5

echo "Creating miner address..."
MINING_ADDR=$(btcctl --simnet --wallet -u $RPC_USER -P $RPC_PASS --rpccert $WALLET_CERT_FILE getnewaddress)
echo $MINING_ADDR > $MINING_ADDR_FILE

echo "Restarting btcd with mining address $MINING_ADDR..."
kill -9 $BTCD_PID
sleep 1
btcd --simnet -u $RPC_USER -P $RPC_PASS --rpclisten=0.0.0.0:18556 --listen=0.0.0.0:18555 \
     --rpccert $CERT_FILE --rpckey $KEY_FILE --miningaddr=$MINING_ADDR 2>&1 &
BTCD_PID=$!

# Allow btcd to start
sleep 5

echo "Generating enough blocks for the first coinbase to mature..."
btcctl --simnet -u $RPC_USER -P $RPC_PASS --rpccert $CERT_FILE generate 100

# Allow some time for the wallet to catch up.
sleep 5

echo "Checking balance..."
btcctl --simnet --wallet -u $RPC_USER -P $RPC_PASS --rpccert $WALLET_CERT_FILE getbalance

echo "Generating a block every ${GENERATE_INTERVAL_SECS} seconds."
echo "Press [CTRL+C] to stop..."
while true
do
  btcctl --simnet -u $RPC_USER -P $RPC_PASS --rpccert $CERT_FILE generate 1
  echo "Periodically send funds to btcstaker address..."
  btcctl --simnet --wallet -u $RPC_USER -P $RPC_PASS --rpccert $WALLET_CERT_FILE walletpassphrase $WALLET_PASS 1
  btcctl --simnet --wallet -u $RPC_USER -P $RPC_PASS --rpccert $WALLET_CERT_FILE sendtoaddress "$BTCSTAKER_ADDR" 10

  sleep ${GENERATE_INTERVAL_SECS}
done
