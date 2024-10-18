#!/bin/bash
set -euo pipefail

# Load environment variables from .env file
echo "Load environment variables from .env file..."
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

if [ -z "$(echo ${WALLET_PASS})" ] || [ -z "$(echo ${BTCSTAKER_PRIVKEY})" ]; then
    echo "Error: WALLET_PASS or BTCSTAKER_PRIVKEY environment variable is not set"
    exit 1
fi
echo "Environment variables loaded successfully"
echo

echo "Checking if Bitcoin node is synced..."
SYNCED=$(docker exec bitcoindsim /bin/sh -c "
    bitcoin-cli \
    -${BITCOIN_NETWORK} \
    -rpcuser=rpcuser \
    -rpcpassword=rpcpass \
    getblockchaininfo" | jq -r '.verificationprogress')
if [ $(echo "$SYNCED < 0.999" | bc -l) -eq 1 ]; then
    echo "Error: Bitcoin node is not fully synced. Expected at least 99.9%, got ${SYNCED}"
    exit 1
fi
echo "Bitcoin node is synced: ${SYNCED}"
echo

BTCSTAKER_WALLET_EXISTS=$(docker exec bitcoindsim /bin/sh -c "
    bitcoin-cli \
    -${BITCOIN_NETWORK} \
    -rpcuser=rpcuser \
    -rpcpassword=rpcpass \
    listwallets" | jq -r '.[] | select(. == "btcstaker")'
)
if [ -z "$BTCSTAKER_WALLET_EXISTS" ]; then
    echo "Creating a wallet for btcstaker..."
    docker exec bitcoindsim /bin/sh -c "
        bitcoin-cli \
        -${BITCOIN_NETWORK} \
        -rpcuser=rpcuser \
        -rpcpassword=rpcpass \
        createwallet btcstaker false false $WALLET_PASS false false"
    echo "Unlocking btcstaker wallet..."
    docker exec bitcoindsim /bin/sh -c "
        bitcoin-cli \
        -${BITCOIN_NETWORK} \
        -rpcuser=rpcuser \
        -rpcpassword=rpcpass \
        -rpcwallet=btcstaker \
        walletpassphrase $WALLET_PASS 10"
    echo "Importing btcstaker private key, it would take several minutes to complete rescan..."
    docker exec bitcoindsim /bin/sh -c "
        bitcoin-cli \
        -${BITCOIN_NETWORK} \
        -rpcuser=rpcuser \
        -rpcpassword=rpcpass \
        -rpcwallet=btcstaker \
        importprivkey $BTCSTAKER_PRIVKEY btcstaker"
    echo "Wallet btcstaker imported successfully"
    echo
    sleep 10
fi

# Check btcstaker address
BTCSTAKER_ADDRESS=$(docker exec bitcoindsim /bin/sh -c "
    bitcoin-cli \
    -${BITCOIN_NETWORK} \
    -rpcuser=rpcuser \
    -rpcpassword=rpcpass \
    -rpcwallet=btcstaker \
    getaddressesbylabel \"btcstaker\"" \
    | jq -r 'keys[] | select(startswith("tb1"))')
echo "BTCStaker address: ${BTCSTAKER_ADDRESS}"

# Check if btcstaker has any unspent transactions
BALANCE_BTC=$(docker exec bitcoindsim /bin/sh -c "
    bitcoin-cli \
    -${BITCOIN_NETWORK} \
    -rpcuser=rpcuser \
    -rpcpassword=rpcpass \
    -rpcwallet=btcstaker \
    listunspent" | jq -r '[.[] | .amount] | add')
if (( $(awk 'BEGIN {print ($BALANCE_BTC < 0.01)}') )); then
    echo "Warning: BTCStaker balance is less than 0.01 BTC. You may need to fund this address for ${BITCOIN_NETWORK}."
else
    echo "BTCStaker balance is sufficient: ${BALANCE_BTC} BTC"
fi
echo
