#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

BTCUSER="rpcuser"
BTCPASSWORD="rpcpass"
BTCWALLET="btcstaker"
BTCWALLETPASS="walletpass"

echo "Wait a bit for bitcoind regtest network to initialize.."
sleep 15

echo -e "$YELLOW"
echo -e "Start Testing Staking Transaction$NC"
echo "Create 2 unsigned staking transactions"
# The first transaction will be used to test the withdraw path
staker_pk_w=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET listunspent" \
    | jq -r '.[0].desc | split("]") | .[1] | split(")") | .[0] | .[2:]')
unsigned_staking_tx_hex_w=$(docker exec unbonding-pipeline /bin/sh -c "cli-tools create-phase1-staking-tx \
    --magic-bytes 62627434 \
    --staker-pk $staker_pk_w \
    --staking-amount 100000 \
    --staking-time 10 \
    --covenant-committee-pks 05149a0c7a95320adf210e47bca8b363b7bd966be86be6392dd6cf4f96995869 \
    --covenant-committee-pks e8d503cb52715249f32f3ee79cee88dfd48c2565cb0c79cf9640d291f46fd518 \
    --covenant-committee-pks fe81b2409a32ddfd8ec1556557e8dd949b6e4fd37047523cb7f5fefca283d542 \
    --covenant-committee-pks bc4a1ff485d7b44faeec320b81ad31c3cad4d097813c21fcf382b4305e4cfc82 \
    --covenant-committee-pks 001e50601a4a1c003716d7a1ee7fe25e26e55e24e909b3642edb60d30e3c40c1 \
    --covenant-quorum 3 \
    --network regtest \
    --finality-provider-pk 03d5a0bb72d71993e435d6c5a70e2aa4db500a62cfaae33c56050deefee64ec0" | jq .staking_tx_hex)

# The second transaction will be used to test the unbonding path
staker_pk_u=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET listunspent" \
    | jq -r '.[-1].desc | split("]") | .[1] | split(")") | .[0] | .[2:]')
unsigned_staking_tx_hex_u=$(docker exec unbonding-pipeline /bin/sh -c "cli-tools create-phase1-staking-tx \
    --magic-bytes 62627434 \
    --staker-pk $staker_pk_u \
    --staking-amount 200000 \
    --staking-time 500 \
    --covenant-committee-pks 05149a0c7a95320adf210e47bca8b363b7bd966be86be6392dd6cf4f96995869 \
    --covenant-committee-pks e8d503cb52715249f32f3ee79cee88dfd48c2565cb0c79cf9640d291f46fd518 \
    --covenant-committee-pks fe81b2409a32ddfd8ec1556557e8dd949b6e4fd37047523cb7f5fefca283d542 \
    --covenant-committee-pks bc4a1ff485d7b44faeec320b81ad31c3cad4d097813c21fcf382b4305e4cfc82 \
    --covenant-committee-pks 001e50601a4a1c003716d7a1ee7fe25e26e55e24e909b3642edb60d30e3c40c1 \
    --covenant-quorum 3 \
    --network regtest \
    --finality-provider-pk 063deb187a4bf11c114cf825a4726e4c2c35fea5c4c44a20ff08a30a752ec7e0" | jq .staking_tx_hex)

echo "Sign the staking transactions through bitcoind wallet"
unsigned_staking_tx_hex_w=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET \
    fundrawtransaction $unsigned_staking_tx_hex_w \
    '{\"feeRate\": 0.00001, \"lockUnspents\": true}' " | jq .hex)
unsigned_staking_tx_hex_u=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET \
    fundrawtransaction $unsigned_staking_tx_hex_u \
    '{\"feeRate\": 0.00001, \"lockUnspents\": true}' " | jq .hex)

# Unlock the wallet
docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET \
    walletpassphrase $BTCWALLETPASS 600"

echo "Sign the staking transactions through the Bitcoin wallet connection"
staking_tx_hex_w=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET \
    signrawtransactionwithwallet $unsigned_staking_tx_hex_w" | jq '.hex')
staking_tx_hex_u=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET \
    signrawtransactionwithwallet $unsigned_staking_tx_hex_u" | jq '.hex')

echo "Send the staking transactions to bitcoind regtest"
staking_txid_w=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET \
    sendrawtransaction $staking_tx_hex_w")
echo "Staking transaction submitted to bitcoind regtest with tx ID $staking_txid_w"

staking_txid_u=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET \
    sendrawtransaction $staking_tx_hex_u")
echo "Staking transaction submitted to bitcoind regtest with tx ID $staking_txid_u"

confirmations=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET \
    gettransaction $staking_txid_u" | jq .confirmations)

# Loop until the number of confirmations is greater than 3
while [ "$confirmations" -le 3 ]
do
    echo "Waiting for the staking transactions to receive 3 BTC confirmations. Current count: $confirmations"
    sleep 10
    confirmations=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET \
        gettransaction $staking_txid_u" | jq .confirmations)
done

echo "Staking transactions received enough confirmations and will be processed by the system"

echo "Wait for the system to process the staking transactions.."
sleep 10

echo "Staking transactions processed and delegations inserted into MongoDB:"
for txid in $staking_txid_w $staking_txid_u
do
    state=$(docker exec mongodb /bin/sh -c "mongosh staking-api-service --eval 'JSON.stringify(db.delegations.find({\"_id\": \"$txid\"}).toArray(), null, 2)'" \
        | jq -r .[].state)
    echo -e "$BLUE  Delegation $txid is tracked and $state $NC"
done
echo -e "$GREEN==Staking is now completed!==$NC"

echo -e "$YELLOW"
echo -e "Start Testing On Demand Unbonding Transaction $NC"
echo "Initiate unbonding for transaction $staking_txid_u through the Staking API Service"
# Create the payload through a helper CLI on the unbonding-pipeline
unbonding_api_payload=$(docker exec unbonding-pipeline /bin/sh -c "cli-tools create-phase1-unbonding-request \
    --magic-bytes 62627434 \
    --covenant-committee-pks 05149a0c7a95320adf210e47bca8b363b7bd966be86be6392dd6cf4f96995869 \
    --covenant-committee-pks e8d503cb52715249f32f3ee79cee88dfd48c2565cb0c79cf9640d291f46fd518 \
    --covenant-committee-pks fe81b2409a32ddfd8ec1556557e8dd949b6e4fd37047523cb7f5fefca283d542 \
    --covenant-committee-pks bc4a1ff485d7b44faeec320b81ad31c3cad4d097813c21fcf382b4305e4cfc82 \
    --covenant-committee-pks 001e50601a4a1c003716d7a1ee7fe25e26e55e24e909b3642edb60d30e3c40c1 \
    --covenant-quorum 3 \
    --network regtest \
    --unbonding-fee 1000 \
    --unbonding-time 5 \
    --staker-wallet-address-host bitcoindsim:18443/wallet/btcstaker \
    --staker-wallet-passphrase $BTCWALLETPASS \
    --staker-wallet-rpc-user $BTCUSER \
    --staker-wallet-rpc-pass $BTCPASSWORD \
    --staking-tx-hex $staking_tx_hex_u")
# Submit the payload to the Staking API Service
curl -sSL localhost:80/v1/unbonding -d "$unbonding_api_payload" > /dev/null 2>&1

echo "Check delegation's $staking_txid_u state in MongoDB:"
state=$(docker exec mongodb /bin/sh -c "mongosh staking-api-service --eval 'JSON.stringify(db.delegations.find({\"_id\": \"$staking_txid_u\"}).toArray(), null, 2)'" \
    | jq -r .[].state)
echo -e "$BLUE  Delegation $staking_txid_u state has transitioned to $state$NC"

echo "Wait for the unbonding pipeline to run.."
sleep 10

unbonding_txid=$(docker exec mongodb /bin/sh -c "mongosh staking-api-service --eval 'JSON.stringify(db.unbonding_queue.find().toArray(), null, 2)'" \
    | jq -r .[].unbonding_tx_hash_hex)
echo "Unbonding transaction submitted to bitcoind regtest with tx ID $unbonding_txid"

echo "Wait for the unbonding time to be fulfilled (5 BTC confirmations).."
sleep 60

echo "Check delegation's $staking_txid_u state in MongoDB:"
state=$(docker exec mongodb /bin/sh -c "mongosh staking-api-service --eval 'JSON.stringify(db.delegations.find({\"_id\": \"$staking_txid_u\"}).toArray(), null, 2)'" \
    | jq -r .[].state)
echo -e "$BLUE  Delegation $staking_txid_u state has transitioned to $state$NC"

echo -e "$GREEN==Unbonding is now completed!==$NC"

echo -e "$YELLOW"
echo -e "Start Testing Withdraw Transaction$NC"
echo "Withdraw the expired staking transaction $staking_txid_w"
# Create and sign the withdrawal transaction through a helper CLI on the
# unbonding pipeline
withdraw_btc_addr=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET listunspent" \
    | jq -r '.[0].address')

withdrawal_tx_hex=$(docker exec unbonding-pipeline /bin/sh -c "cli-tools create-phase1-withdaw-request \
    --magic-bytes 62627434 \
    --covenant-committee-pks 05149a0c7a95320adf210e47bca8b363b7bd966be86be6392dd6cf4f96995869 \
    --covenant-committee-pks e8d503cb52715249f32f3ee79cee88dfd48c2565cb0c79cf9640d291f46fd518 \
    --covenant-committee-pks fe81b2409a32ddfd8ec1556557e8dd949b6e4fd37047523cb7f5fefca283d542 \
    --covenant-committee-pks bc4a1ff485d7b44faeec320b81ad31c3cad4d097813c21fcf382b4305e4cfc82 \
    --covenant-committee-pks 001e50601a4a1c003716d7a1ee7fe25e26e55e24e909b3642edb60d30e3c40c1 \
    --covenant-quorum 3 \
    --network regtest \
    --withdraw-tx-fee 1000 \
    --withdraw-tx-destination $withdraw_btc_addr \
    --staker-wallet-address-host bitcoindsim:18443/wallet/btcstaker \
    --staker-wallet-passphrase $BTCWALLETPASS \
    --staker-wallet-rpc-user $BTCUSER \
    --staker-wallet-rpc-pass $BTCPASSWORD \
    --staking-tx-hex $staking_tx_hex_w" | jq -r .withdraw_tx_hex)

# Send the signed withdrawal transaction
echo "Send the withdrawal transaction to bitcoind regtest"
withdrawal_txid=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET \
    sendrawtransaction $withdrawal_tx_hex")
echo "Withdrawal transaction submitted to bitcoind regtest with tx ID $withdrawal_txid"

echo "Wait for the system to process the withdrawal transaction (upon receival of 3 BTC confirmations).."
sleep 40

echo "Check delegation's $staking_txid_w state in MongoDB:"
state=$(docker exec mongodb /bin/sh -c "mongosh staking-api-service --eval 'JSON.stringify(db.delegations.find({\"_id\": \"$staking_txid_w\"}).toArray(), null, 2)'" \
    | jq -r .[].state)
echo -e "$BLUE  Delegation $staking_txid_w state has transitioned to $state$NC"

echo -e "$GREEN==Withdrawal is now completed!==$NC"
