#!/bin/bash
set -euo pipefail

echo "Verifying Bitcoin network..."
# Check Bitcoin network
NETWORK=$(docker exec bitcoindsim /bin/sh -c "
    bitcoin-cli \
    -${BITCOIN_NETWORK} \
    -rpcuser=rpcuser \
    -rpcpassword=rpcpass \
    getblockchaininfo" | jq -r '.chain')
if [ "$NETWORK" != "$BITCOIN_NETWORK" ]; then
    echo "Error: Bitcoin network mismatch. Expected ${BITCOIN_NETWORK}, got ${NETWORK}"
    exit 1
fi
echo "Bitcoin network: ${NETWORK}"

# Check btcstaker address
# BTCSTAKER_ADDRESS=$(docker exec bitcoindsim /bin/sh -c "
#     bitcoin-cli \
#     -${BITCOIN_NETWORK} \
#     -rpcuser=rpcuser \
#     -rpcpassword=rpcpass \
#     -rpcwallet=btcstaker \
#     getaddressesbylabel \"btcstaker\"" \
#     | jq -r 'keys[] | select(startswith("tb1"))')
# echo "BTCStaker address: ${BTCSTAKER_ADDRESS}"

# Get address balance using mempool.space API
BTCSTAKER_ADDRESS="tb1qdfrvwahpgndfn8s7nkwhxlzwexgeahz5a2z9ul"
if [ "$BITCOIN_NETWORK" == "signet" ]; then
    BALANCE=$(curl -sSL "https://mempool.space/signet/api/address/${BTCSTAKER_ADDRESS}/utxo" | jq -r '[.[].value] | add // 0')
    BALANCE_BTC=$(echo "scale=8; $BALANCE / 100000000" | bc)
    echo "BTCStaker balance: ${BALANCE_BTC} BTC"

    if [ $(echo "$BALANCE == 0" | bc -l) -eq 1 ]; then
        echo "Warning: BTCStaker balance is 0. You may need to fund this address for signet."
    fi
else
    echo "Skipping balance check for regtest network."
fi

echo "Bitcoin network verification completed successfully."
