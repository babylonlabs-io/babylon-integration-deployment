#!/bin/sh
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
BTCCMD="bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET"
BTCCLI="docker exec bitcoindsim /bin/sh -c "
LOCATE=$(dirname "$(realpath "$0")")
DIR="$LOCATE/.testnets/demo"

# The first transaction will be used to test the withdraw path

init() {
    echo "Wait a bit for bitcoind regtest network to initialize.."
    # sleep 25
    mkdir -p $DIR
    echo "$YELLOW Start End to End Test $NC"
}

create_staking_tx() {
    staking_amount=$1
    staking_time=$2
    folder=$DIR/$staking_amount
    staker_pk=$($BTCCLI "$BTCCMD listunspent" | jq -r '.[0].desc | split("]") | .[1] | split(")") | .[0] | .[2:]')
    unsigned_staking_tx_hex=$(docker exec unbonding-pipeline /bin/sh -c "cli-tools create-phase1-staking-tx \
        --magic-bytes 62627434 \
        --staker-pk $staker_pk \
        --staking-amount $staking_amount \
        --staking-time $staking_time \
        --covenant-committee-pks 0342301c4fdb5b1ab27a80a04d95c782f720874265889412a80d270feeb456f1f7 \
        --covenant-committee-pks 03a4d2276a2a09f0e14d6a74901fec0aab3d1edf0dd22a690260acca48f5d5b3c0 \
        --covenant-committee-pks 02707f3d6bf2334ecb7c336fc7babd400afa9132a34f84406b28865d06e0ba81e8 \
        --covenant-quorum 2 \
        --network regtest \
        --finality-provider-pk 03d5a0bb72d71993e435d6c5a70e2aa4db500a62cfaae33c56050deefee64ec0" | jq .staking_tx_hex)

    # echo "Sign the staking transactions through bitcoind wallet"
    unsigned_staking_tx_hex=$($BTCCLI "$BTCCMD \
        fundrawtransaction $unsigned_staking_tx_hex \
        '{\"feeRate\": 0.00001, \"lockUnspents\": true}' " | jq .hex)

    # Unlock the wallet
    $BTCCLI "$BTCCMD walletpassphrase $BTCWALLETPASS 600"

    # echo "Sign the staking transactions through the Bitcoin wallet connection"
    staking_tx_hex=$($BTCCLI "$BTCCMD signrawtransactionwithwallet $unsigned_staking_tx_hex" | jq '.hex')
    # echo "Send the staking transactions to bitcoind regtest"
    staking_txid=$($BTCCLI "$BTCCMD sendrawtransaction $staking_tx_hex")
    mkdir -p $folder
    echo "$staking_tx_hex" > $folder/tx_hex
    BTC=$(($staking_amount / 100000000))
    echo "Sign and send a staking transaction with stake: $BTC BTC and staking term: $staking_time blocks"
    echo "Staking transaction submitted to bitcoind regtest with tx ID: $BLUE $staking_txid $NC"
    echo "$staking_txid" > $folder/tx_id
}

create_unbonding_tx() {
    tx_hex=$1
    unbonding_time=$2

    # Create the payload through a helper CLI on the unbonding-pipeline
    unbonding_api_payload=$(docker exec unbonding-pipeline /bin/sh -c "cli-tools create-phase1-unbonding-request \
        --magic-bytes 62627434 \
        --covenant-committee-pks 0342301c4fdb5b1ab27a80a04d95c782f720874265889412a80d270feeb456f1f7 \
        --covenant-committee-pks 03a4d2276a2a09f0e14d6a74901fec0aab3d1edf0dd22a690260acca48f5d5b3c0 \
        --covenant-committee-pks 02707f3d6bf2334ecb7c336fc7babd400afa9132a34f84406b28865d06e0ba81e8 \
        --covenant-quorum 2 \
        --network regtest \
        --unbonding-fee 500 \
        --unbonding-time $unbonding_time \
        --staker-wallet-address-host bitcoindsim:18443/wallet/btcstaker \
        --staker-wallet-passphrase $BTCWALLETPASS \
        --staker-wallet-rpc-user $BTCUSER \
        --staker-wallet-rpc-pass $BTCPASSWORD \
        --staking-tx-hex $tx_hex")
    # Submit the payload to the Staking API Service
    echo "$unbonding_api_payload"
    curl -sSL localhost:80/v1/unbonding -d "$unbonding_api_payload"
    echo ""
}

create_withdraw_tx() {
    tx_hex=$1
    withdraw_btc_addr=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET listunspent" \
        | jq -r '.[0].address')

    withdrawal_tx_hex=$(docker exec unbonding-pipeline /bin/sh -c "cli-tools create-phase1-withdaw-request \
        --magic-bytes 62627434 \
        --covenant-committee-pks 0342301c4fdb5b1ab27a80a04d95c782f720874265889412a80d270feeb456f1f7 \
        --covenant-committee-pks 03a4d2276a2a09f0e14d6a74901fec0aab3d1edf0dd22a690260acca48f5d5b3c0 \
        --covenant-committee-pks 02707f3d6bf2334ecb7c336fc7babd400afa9132a34f84406b28865d06e0ba81e8 \
        --covenant-quorum 2 \
        --network regtest \
        --withdraw-tx-fee 1000 \
        --withdraw-tx-destination $withdraw_btc_addr \
        --staker-wallet-address-host bitcoindsim:18443/wallet/btcstaker \
        --staker-wallet-passphrase $BTCWALLETPASS \
        --staker-wallet-rpc-user $BTCUSER \
        --staker-wallet-rpc-pass $BTCPASSWORD \
        --staking-tx-hex $tx_hex" | jq -r .withdraw_tx_hex)
    
    echo "Send the withdrawal transactions to bitcoind regtest"
    withdrawal_txid=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET \
        sendrawtransaction $withdrawal_tx_hex")
    echo "Withdrawal transaction submitted to bitcoind regtest with tx ID $BLUE $withdrawal_txid $NC"
}

create_unbonding_withdraw_tx() {
    tx_hex=$1
    unbonding_hex=$2
    unbonding_time=$3

    withdraw_btc_addr=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET listunspent" \
        | jq -r '.[0].address')

    withdrawal_tx_hex=$(docker exec unbonding-pipeline /bin/sh -c "cli-tools create-phase1-withdaw-request \
        --magic-bytes 62627434 \
        --covenant-committee-pks 0342301c4fdb5b1ab27a80a04d95c782f720874265889412a80d270feeb456f1f7 \
        --covenant-committee-pks 03a4d2276a2a09f0e14d6a74901fec0aab3d1edf0dd22a690260acca48f5d5b3c0 \
        --covenant-committee-pks 02707f3d6bf2334ecb7c336fc7babd400afa9132a34f84406b28865d06e0ba81e8 \
        --covenant-quorum 2 \
        --network regtest \
        --withdraw-tx-fee 1000 \
        --withdraw-tx-destination $withdraw_btc_addr \
        --staker-wallet-address-host bitcoindsim:18443/wallet/btcstaker \
        --staker-wallet-passphrase $BTCWALLETPASS \
        --staker-wallet-rpc-user $BTCUSER \
        --staker-wallet-rpc-pass $BTCPASSWORD \
        --staking-tx-hex $tx_hex \
        --unbonding-tx-hex  $unbonding_hex \
        --unbonding-time $unbonding_time" | jq -r .withdraw_tx_hex)

    echo "Send the withdrawal transactions to bitcoind regtest"
    withdrawal_txid=$(docker exec bitcoindsim /bin/sh -c "bitcoin-cli -regtest -rpcuser=$BTCUSER -rpcpassword=$BTCPASSWORD -rpcwallet=$BTCWALLET \
        sendrawtransaction $withdrawal_tx_hex")
    echo "Withdrawal transaction submitted to bitcoind regtest with tx ID $BLUE $withdrawal_txid $NC"
}

current_info() {
    height=$($BTCCLI "$BTCCMD getblockcount")
    echo "$BLUE Current Height $height $NC"
}

check_mongoDB_info() {
    txid=$1
    echo "Checking transaction with ID:$BLUE $1 $NC"
    target_stats=$2
    target_overflow=$3
    while true; do
        state=$(docker exec mongodb /bin/sh -c "mongosh staking-api-service --eval 'JSON.stringify(db.delegations.find({\"_id\": \"$txid\"}).toArray(), null, 2)'" \
        | jq -r .[].state)

        if [ "$state" = "$target_stats" ]; then
                is_overflow=$(docker exec mongodb /bin/sh -c "mongosh staking-api-service --eval 'JSON.stringify(db.delegations.find({\"_id\": \"$txid\"}).toArray(), null, 2)'" \
                | jq -r .[].is_overflow)
                if [ "$is_overflow" = "$target_overflow" ]; then
                    echo "$GREEN Target metrics achieved! Transaction state: $state and Overflow status: $target_overflow $NC"
                    break
                fi
            echo "$RED Target metrics not met; overflow status: $is_overflow, while expected state is $target_overflow $NC"
            exit 1
        fi
        sleep 1
    done
}

get_unbonding_mongoDB_info() {
    id=$1
    txid=$2
    echo "get unbonding tx in mongo: $BLUE $txid $NC"
    unbonding_tx_hex=$(docker exec mongodb /bin/sh -c "mongosh staking-api-service --eval 'JSON.stringify(db.delegations.find({\"_id\": \"$txid\"}).toArray(), null, 2)'" \
        | jq -r .[].unbonding_tx.tx_hex)
    echo $unbonding_tx_hex > $DIR/$1/unbonding_hex
}

check_staking_status() {
    expect_active_delegations=$1
    expect_total_delegations=$2
    res=$(curl -s 'localhost/v1/stats')
    active_delegations=$(echo $res | jq -r .data.active_delegations )
    total_delegations=$(echo $res | jq -r .data.total_delegations )
    if [ "$active_delegations" -eq "$expect_active_delegations" ]; then
        echo "$GREEN Target metrics achieved! Active delegation count: $active_delegations $NC"
    else
        echo "$RED Target metrics not met; Active delegation count: $active_delegations $NC"
        exit 1
    fi

    if [ "$total_delegations" -eq "$expect_total_delegations" ]; then
        echo "$GREEN Target metrics achieved! Total delegation count: $total_delegations $NC"
    else
        echo "$RED Target metrics not met; Total delegation count: $total_delegations $NC"
        exit 1
    fi
}

check_staking_tvl() {
    expect_active_tvl=$1
    expect_total_tvl=$2
    expect_unconfirmed_tvl=$3
    res=$(curl -s 'localhost/v1/stats')
    active_tvl=$(echo $res | jq -r .data.active_tvl )
    total_tvl=$(echo $res | jq -r .data.total_tvl )
    unconfirmed_tvl=$(echo $res | jq -r .data.unconfirmed_tvl )
    if [ "$active_tvl" -eq "$expect_active_tvl" ]; then
        echo "$GREEN Target metrics achieved! Active TVL: $active_tvl $NC"
    else
        echo "$RED Target metrics not met; Active TVL: $active_tvl $NC"
        exit 1
    fi

    if [ "$total_tvl" -eq "$expect_total_tvl" ]; then
        echo "$GREEN Target metrics achieved! Total TVL: $total_tvl $NC"
    else
        echo "$RED Target metrics not met; Total TVL: $total_tvl $NC"
        exit 1
    fi

    if [ "$unconfirmed_tvl" -eq "$expect_unconfirmed_tvl" ]; then
        echo "$GREEN Target metrics achieved! Unconfirmed TVL: $unconfirmed_tvl $NC"
    else
        echo "$RED Target metrics not met; Unconfirmed TVL: $unconfirmed_tvl $NC"
        exit 1
    fi
}

check_indexer_metrics() {
    field=$1
    type=$2
    expect_count=$3
    while true; do
        count=$(curl -s localhost:2112/metrics | grep "$field" | grep "$type" | grep -v '#' | cut -d' ' -f2)
        if [ $count -eq $expect_count ]; then
            echo "$GREEN Target metrics achieved! Invalid transaction count on Staking Indexer: $count $NC"
            break
        else
            sleep 2
        fi
    done
}

move_next_block() {
    wait=10
    echo "Next bitcoin block will be produced in $wait seconds..."
    sleep 10
    current_info
}

move_to_block() {
    echo "Generating enough bitcoin blocks to reach bitcoin height $1..."
    target_block=$1
    while true; do
        height=$($BTCCLI "$BTCCMD getblockcount")
        if [ "$height" -eq "$target_block" ]; then
            echo "$BLUE Reached target bitcoin height $target_block $NC"
            break
        else
            sleep 3
        fi
    done
}

print_global_parameters() {
    ver=$1
    echo "Current Active Global Parameters"
    curl -s --location '0.0.0.0:80/v1/global-params' | jq --arg version "$ver" '.data.versions[] | select(.version == ($version | tonumber))'
}

invalid_block() {
    # Get the latest block hash
    latest_block_hash=$($BTCCLI "$BTCCMD getbestblockhash")
    echo "The latest bitcoin block with hash $latest_block_hash will now be invalidated..."

    # Invalidate the latest block
    $BTCCLI "$BTCCMD invalidateblock $latest_block_hash"
    transactions=$($BTCCLI "$BTCCMD getblock $latest_block_hash" | jq -r '.tx[]')
}

init
print_global_parameters 0
current_info

echo ""
echo "$YELLOW===== ### Scenario 1: No transactions are processed by the system before the first activation height ===== $NC"
create_staking_tx 600000000 1000 # 6 BTC
move_next_block
move_next_block
check_indexer_metrics "si_total_staking_txs" "" 0
check_staking_status 0 0

echo ""
echo "$YELLOW===== Scenario 2: Submit Staking Transactions and fill the staking cap ===== $NC"
move_to_block 115
# At height 115, we send 2 txs with stake 2 BTC, 8 BTC
create_staking_tx 200000000 1000 # 2 BTC
create_staking_tx 800000000 1000 # 8 BTC

# At height 116, we send 1 tx with stake 1 BTC
move_next_block
create_staking_tx 100000000 1000 # 1 BTC

# At height 117, both the txs are active with total active stake 10 BTC
move_next_block
check_mongoDB_info $(cat $DIR/200000000/tx_id) "active" "false"
check_mongoDB_info $(cat $DIR/800000000/tx_id) "active" "false"

# At height 118, this tx will be mark as overflow due to TVL exceeding the staking cap
move_next_block
check_mongoDB_info $(cat $DIR/100000000/tx_id) "active" "true"
check_staking_status 2 2

# At height 119, we unbond the 2 BTC delegation with unbonding_time 2
echo ""
echo "$YELLOW===== Scenario 3: Submit on-demand unbonding transaction and ensure the system re-opens ===== $NC"
move_next_block
create_unbonding_tx $(cat $DIR/200000000/tx_hex) 3
check_mongoDB_info $(cat $DIR/200000000/tx_id) "unbonding_requested" "false"

# At height 121, we create 1 tx with stake 1 BTC, mongo stats change 2 BTC's tx to unbonding
move_next_block
check_mongoDB_info $(cat $DIR/200000000/tx_id) "unbonding" "false"
get_unbonding_mongoDB_info 200000000 $(cat $DIR/200000000/tx_id)
check_staking_status 1 2
create_staking_tx 100000000 1000 # 1 BTC

# At height 124, staked 1 tx should be active and not overflow
move_next_block
move_next_block
check_mongoDB_info $(cat $DIR/100000000/tx_id) "active" "false"

# At height 125, mongo stats change 2 BTC tx to unbonded
move_next_block
check_mongoDB_info $(cat $DIR/200000000/tx_id) "unbonded" "false"

echo ""
echo "$YELLOW===== Scenario 4: Withdraw an on-demand unbonded transaction ===== $NC"
# At height 126, we withdraw unbonded tx
move_next_block
create_unbonding_withdraw_tx $(cat $DIR/200000000/tx_hex) $(cat $DIR/200000000/unbonding_hex) 3

# At height 127, mongo stats change to withdrawn
move_next_block
check_mongoDB_info $(cat $DIR/200000000/tx_id) "withdrawn" "false"
check_staking_status 2 3

# At height 130
echo ""
echo "$YELLOW===== Scenario 5: Ensure staking parameter update is enforced ===== $NC"
move_to_block 130
print_global_parameters 1
create_staking_tx 150000000 1000 # 1.5 BTC

# At height 132, indexer should find out this invalid transaction and record in the metrcis
move_next_block
move_next_block
check_indexer_metrics "si_invalid_txs_counter" "unconfirmed_staking_transaction" 1

# At height 133
echo ""
echo "$YELLOW===== Scenario 6: Withdraw a transaction that has exceeded its timelock ===== $NC"
move_next_block
create_staking_tx 500000000 2 # 5 BTC with 2 block timelock

# At height 134, indexer should get the unconfirmed tx and send btc info to api service
move_next_block
sleep 3 # process into queue
check_staking_tvl 900000000 1100000000 1400000000

# At height 135 we wait for block timelock expired and pick up by expiry service
move_next_block
check_mongoDB_info $(cat $DIR/500000000/tx_id) "unbonded" "false"
check_staking_tvl 1400000000 1600000000 1400000000

# At height 137, we withdraw this tx
move_next_block
create_withdraw_tx $(cat $DIR/500000000/tx_hex)

# At height 138, mongo stats change to withdrawn
move_next_block
check_mongoDB_info $(cat $DIR/500000000/tx_id) "withdrawn" "false"
check_staking_status 3 4

# At height 140
echo ""
echo "$YELLOW===== Scenario 7: Ensure the system can survive BTC forks ===== $NC"
move_to_block 140
create_staking_tx 700000000 1000 # 7 BTC with 1000 block timelock
move_next_block
sleep 3
invalid_block
move_next_block
move_next_block
check_mongoDB_info $(cat $DIR/700000000/tx_id) "active" "false"

echo "$YELLOW===== Congratulations! All tests are passed!!! ===== $NC"
