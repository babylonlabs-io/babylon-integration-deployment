#!/bin/bash
set -euo pipefail

echo "Checking if Bitcoin node is synced..."
SYNCED=$(docker exec bitcoindsim /bin/sh -c "
    bitcoin-cli \
    -signet \
    -rpcuser=rpcuser \
    -rpcpassword=rpcpass \
    getblockchaininfo" | jq -r '.verificationprogress')
if [ $(echo "$SYNCED < 0.999" | bc -l) -eq 1 ]; then
    echo "Error: Bitcoin node is not fully synced. Expected at least 99.9%, got ${SYNCED}"
    exit 1
fi
echo "Bitcoin node is synced: ${SYNCED}"

# Check btcstaker address
BTCSTAKER_ADDRESS=$(docker exec bitcoindsim /bin/sh -c "
    bitcoin-cli \
    -signet \
    -rpcuser=rpcuser \
    -rpcpassword=rpcpass \
    -rpcwallet=btcstaker \
    getaddressesbylabel \"btcstaker\"" \
    | jq -r 'keys[] | select(startswith("tb1"))')
echo "BTCStaker address: ${BTCSTAKER_ADDRESS}"

# Check if btcstaker has any unspent transactions
BALANCE_BTC=$(docker exec bitcoindsim /bin/sh -c "
    bitcoin-cli \
    -signet \
    -rpcuser=rpcuser \
    -rpcpassword=rpcpass \
    -rpcwallet=btcstaker \
    listunspent" | jq -r '[.[] | .amount] | add')
if [ $(echo "$BALANCE_BTC < 0.01" | bc -l) -eq 1 ]; then
    echo "Warning: BTCStaker balance is less than 0.01 BTC. You may need to fund this address for signet."
fi