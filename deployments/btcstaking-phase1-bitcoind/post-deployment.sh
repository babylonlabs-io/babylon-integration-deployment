#!/bin/bash
RPCUSER="rpcuser"
RPCPASSWORD="rpcpass"
RPCWALLET="covenant-signer"
RPCWALLETPASS="walletpass"

[[ "$(uname)" == "Linux" ]] && chown -R 1138:1138 .testnets/staking-indexer

# Restore the covenant-signer wallet
echo "Restoring the covenant-signer wallet"
docker exec bitcoindsim-signer /bin/sh -c "
bitcoin-cli -regtest -rpcuser="$RPCUSER" -rpcpassword="$RPCPASSWORD" restorewallet "$RPCWALLET" /bitcoindsim/.bitcoin/covenant-signer.dat
"

# Unlock the covenant-signer wallet
echo "Unlocking the covenant-signer wallet"
docker exec bitcoindsim-signer /bin/sh -c "
bitcoin-cli -regtest -rpcuser="$RPCUSER" -rpcpassword="$RPCPASSWORD" -rpcwallet="$RPCWALLET" walletpassphrase "$RPCWALLETPASS" 36000
"