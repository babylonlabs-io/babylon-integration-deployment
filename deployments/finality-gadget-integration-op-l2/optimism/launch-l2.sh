#!/bin/bash
set -euo pipefail

OP_DIR=$1
OP_DEPLOY_DIR=$2
source $OP_DEPLOY_DIR/utils.sh

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

# Launch the OP L2
echo "Launching the OP L2..."
PWD=$OP_DEPLOY_DIR docker compose -f $OP_DEPLOY_DIR/docker-compose.yml up -d l2

# Wait for the OP L2 to be available
echo "Waiting for OP L2 to be available..."
wait_up 9545
sleep 5
echo

# Launch the OP Node, Proposer and Batcher
echo "Launching the OP Node, Proposer and Batcher..."
PWD=$OP_DEPLOY_DIR docker compose -f $OP_DEPLOY_DIR/docker-compose.yml up -d op-node op-proposer op-batcher

# Wait for the OP Node to be available
echo "Waiting for OP Node, Proposer and Batcher to be available..."
wait_up 7545
wait_up 7546
wait_up 7547
echo
