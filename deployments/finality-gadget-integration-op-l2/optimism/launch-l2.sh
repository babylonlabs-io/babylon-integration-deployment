#!/bin/bash
set -euo pipefail


OP_DIR=$1
OP_DEPLOY_DIR=$2

# set the needed environment variable
echo "Setting the needed environment variable..."
if [ "$DEVNET_L2OO" = true ]; then
  export L2OO_ADDRESS=$(jq -r .L2OutputOracleProxy < $OP_DIR/packages/contracts-bedrock/deployments/sepolia-devnet-${L2_CHAIN_ID}.json)
else
  export DGF_ADDRESS=$(jq -r .DisputeGameFactoryProxy < $OP_DIR/packages/contracts-bedrock/deployments/sepolia-devnet-${L2_CHAIN_ID}.json)
  # these two values are from the bedrock-devnet
  export DG_TYPE=254
  export PROPOSAL_INTERVAL=12s
fi
if [ "$DEVNET_ALTDA" = true ]; then
  export ALTDA_ENABLED=true
  export DA_TYPE=calldata
else
  export ALTDA_ENABLED=false
  export DA_TYPE=blobs
fi
if [ "$GENERIC_ALTDA" = true ]; then
  export ALTDA_GENERIC_DA=true
  export ALTDA_SERVICE=true
else
  export ALTDA_GENERIC_DA=false
  export ALTDA_SERVICE=false
fi
echo

wait_up() {
    local port=$1
    local retries=10
    local wait_time=1

    for i in $(seq 1 $retries); do
        if nc -z localhost $port; then
            echo "Port $port is available"
            return 0
        fi
        echo "Attempt $i: Port $port is not available yet. Waiting $wait_time seconds..."
        sleep $wait_time
    done

    echo "Error: Port $port did not become available after $retries attempts"
    return 1
}

# Launch the OP L2
echo "Launching the OP L2..."
PWD=$OP_DEPLOY_DIR docker compose -f $OP_DEPLOY_DIR/docker-compose.yml up -d l2

# Wait for the OP L2 to be available
echo "Waiting for OP L2 to be available..."
wait_up 9545

L2_CHAIN_ID=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d '{"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}' \
    http://localhost:9545 | jq -r '.result' | xargs printf '%d\n')
echo "OP L2 is up and running with the L2 chain id: $L2_CHAIN_ID"
echo

# Launch the OP Node, Proposer and Batcher
echo "Launching the OP Node, Proposer and Batcher..."
PWD=$OP_DEPLOY_DIR docker compose -f $OP_DEPLOY_DIR/docker-compose.yml up -d op-node op-proposer op-batcher

# Wait for the OP Node to be available
echo "Waiting for OP Node, Proposer and Batcher to be available..."
wait_up 7545
wait_up 7546
wait_up 7547
curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
    http://localhost:7545 | \
    jq '.result | {
        head_l1_number: .head_l1.number,
        safe_l1_number: .safe_l1.number,
        finalized_l1_number: .finalized_l1.number,
        unsafe_l2_number: .unsafe_l2.number,
        safe_l2_number: .safe_l2.number,
        finalized_l2_number: .finalized_l2.number
    }'
echo "OP Node, Proposer and Batcher are up and running"
echo
